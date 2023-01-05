extends Node

#TODO? : Check for host machine endianess
#TODO: Randomize STUN server to send

signal external_address_resolved(ip, port)
signal time_out

export var time_out = 2.0
export var maximum_resend = 3
export var response_check_interval = 0.2


var _responseCheckTimer
var _timeoutDeadline
var _resendLeft
var _lastTransactionID
var _pp = PacketPeerUDP.new()

# 64 first header bits
enum Type{
	BITS    			= 0x01_10_0000, #0b00_000001_0001_0000_00000000_00000000
	REQUEST 			= 0x00_00_0000, #0b00_000000_0000_0000_00000000_00000000
	SUCCESS_RESPONSE	= 0x01_00_0000, #0b00_000001_0000_0000_00000000_00000000
}
enum Method{
	BITS				= 0x3E_EF_0000, #0b00_111110_1110_1111_00000000_00000000
	BINDING 			= 0x00_01_0000, #0b00_000000_0000_0001_00000000_00000000
}
enum Format{
	ZEROES_PREFIX		= 0xC0_00_0000,
	MESSAGE_LENGTH		= 0x00_00_FFFF,
	MAGIC_COOKIE		= 0x2112A442,
}


enum Attribute{
	TYPE				= 0xFFFF0000
	LENGTH				= 0x0000FFFF
	
	MAPPED_ADDRESS 		= 0x00010000
	XOR_MAPPED_ADDRESS	= 0x00200000
	MAPPED_ADDRESS_FML	= 0x00FF0000
	MAPPED_ADDRESS_IPvF	= 0x00010000
	MAPPED_ADDRESS_IPvS	= 0x00020000
	MAPPED_ADDRESS_PORT	= 0x0000FFFF
	XOR_COOKIE			= 0x21122112
}


#func _ready():
#	GetExternalAddress(7979)
	

func GetExternalAddress(client_port):
	_pp.listen(client_port)
	_pp.set_dest_address("stun4.l.google.com", 19302)
	
	_timeoutDeadline = Time.get_ticks_msec() + time_out * 1000
	_resendLeft = maximum_resend
	SendBindingRequest()


func SendBindingRequest():
	_pp.put_packet(_GenerateNewBindingRequest())
	_CreateResponseCheckTimer()
	

func _checkForResponse():
	var packet
	packet = _pp.get_packet()
	
	while _pp.get_packet_error() == OK:
		if _DissectResponse(packet) == true:
			return
			
	if Time.get_ticks_msec() > _timeoutDeadline:
		_resendLeft = _resendLeft - 1
		if _resendLeft == 0:
			emit_signal("time_out")
			return
		SendBindingRequest()
	else:
		_CreateResponseCheckTimer()


func _CloseSocket():
	_pp.close()
		
	
func _CreateResponseCheckTimer():
	_responseCheckTimer = get_tree().create_timer(response_check_interval)
	_responseCheckTimer.connect("timeout", self, "_checkForResponse", [], CONNECT_ONESHOT)


func _GenerateNewBindingRequest():
	return _FormulateHeader(Type.REQUEST, Method.BINDING, 0)


# WARNING: var2bytes() puts bytes in Little Endian order.
# Use PoolByteArray.invert() to make them Big Endian.
func _FormulateHeader(type, method, content_length):
	
	var zeroes_type_length = var2bytes(\
								type | method | (content_length & Format.MESSAGE_LENGTH)
								& ~Format.ZEROES_PREFIX\
								).subarray(4, 7)
	zeroes_type_length.invert()
	
	var magic_cookie = var2bytes(Format.MAGIC_COOKIE).subarray(4, 7)
	magic_cookie.invert()
	
	var header = zeroes_type_length + magic_cookie
	# WARNING: I'm counting on garbage made from resize() to be random enough
	header.resize(20)
	_lastTransactionID = _EncodeIntArray(header.subarray(8, 19))
	
	return header


# Return true if this is the response to STUN request
func _DissectResponse(response):
	response = _EncodeIntArray(response)
	if not _IsValid(response):
		printerr("STUN response is invalid")
		return false
	
	var attributes = _ExtractAttributes(response)
	for attr in attributes:
		if attr[0] == Attribute.XOR_MAPPED_ADDRESS:
			_GetXORMappedAddress(attr[1])
		else: #TODO: More Attribute types?
			print("Attribute not yet implemented: " + str(var2bytes(attr[0])))
	return true
			
			
func _GetXORMappedAddress(attribute):
	var family	= attribute[0] & Attribute.MAPPED_ADDRESS_FML
	var port	= (attribute[0] & Attribute.MAPPED_ADDRESS_PORT) ^ Format.MAGIC_COOKIE >> 16
	var xaddress= attribute.slice(1, attribute.size())

	
	for everyFourBytes in xaddress:
		everyFourBytes = everyFourBytes ^ Attribute.XOR_COOKIE
	
	var resolved_address = _ConvertIPValueToString(family, xaddress)
	# TODO: WARN: Closing socket here might causes a problem later on when we forget it
	# As long as we only use this for XOR MAPPED ADDRESS, I guess it'll be fine
	_CloseSocket()
	emit_signal("external_address_resolved", resolved_address, port)


# Convert ip_value to String representation
# @ip_type is Attribute.MAPPED_ADDRESS_IPvF or Attribute.MAPPED_ADDRESS_IPvS
# @ip_value is an Array of ints. 
# 1 int for Attribute.MAPPED_ADDRESS_IPvF 
# 4 ints for Attribute.MAPPED_ADDRESS_IPvS 
# TODO: Convert IPv6
func _ConvertIPValueToString(ip_type, ip_value):
	if ip_type == Attribute.MAPPED_ADDRESS_IPvF:
		var result = ""
		for i in range(3, -1, -1):
			result += str((ip_value[0] & (0xFF << i*8)) >> i*8) + "."
		result.erase(result.length() - 1, 1)
		return result
	elif ip_type == Attribute.MAPPED_ADDRESS_IPvS:
		printerr("Conversion to IPv6 not yet implemented")
	else:
		printerr("Unknown ip_type: \"" + str(ip_type) + "\"")


# Return an array of entries.
# Each entry is in the form [TYPE, CONTENT]
# LENGTH is omitted, as it's already stored in the array CONTENT
func _ExtractAttributes(response: Array):
	var results = []
	var read_head = 5	# Start reading from the 6th integer
	while read_head < response.size():
		var length = response[read_head] & Attribute.LENGTH
		results.push_back([response[read_head] & Attribute.TYPE,\
							response.slice(read_head + 1, read_head + 1 + length)])
		read_head = read_head + 1 + length
	return results


	
func _IsValid(response):
	if response[0] & Format.ZEROES_PREFIX != 0 or\
		response[1] & Format.MAGIC_COOKIE != Format.MAGIC_COOKIE or\
		response.slice(2, 4) != _lastTransactionID:
			return false
	return true


# Working with PoolByteArray is too difficult
# Turn it into Array of ints to bitwising easier
func _EncodeIntArray(response: PoolByteArray):
	var result = []
	for i in range(0, response.size(), 4):
		var next_int = 0
		for j in range(0, 4):
			next_int |= (response[i+j] << 8*(3-j))
		result.push_back(next_int)
	return result


func _on_RFC8489_STUN_external_address_resolved(_ip, _port):
	_CloseSocket()


func _on_RFC8489_STUN_time_out():
	_CloseSocket()
