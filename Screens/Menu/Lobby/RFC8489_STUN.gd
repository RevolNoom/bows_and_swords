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


class StunMessage:
	var first32bit
	var length
	var type
	var method
	var magicCookie
	var transactionID
	var attributes


# 32 first header bits
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
	var err = _pp.listen(client_port)
	if err != OK:
		printerr("Can't listen on port " + str(client_port) + ". Error code: " + str(err))
		return
	
	err = _pp.set_dest_address("stun4.l.google.com", 19302)
	if err != OK:
		printerr("Failed to set STUN address. Error code: " + str(err))
		return
	
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
		var response = _FormulateResponse(packet)
		if not _IsValid(response):
			printerr("STUN response is invalid")
			return
			
		for attribute in response.attributes:
			if attribute[0] == Attribute.XOR_MAPPED_ADDRESS:
				_GetXORMappedAddress(attribute[1], response)
			else: #TODO: More Attribute types?
				print("Attribute not yet implemented: " + str(var2bytes(attribute[0]).subarray(4, 7)))
		return true
			
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
	
	# Subarray(4, 7) because Variant contains another 4-byte Type field prefix
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
	#print("sending transaction ID: " + str(_lastTransactionID))
	
	return header

	

func _FormulateResponse(response) -> StunMessage:
	if response.size() < 5:
		printerr("STUN response too short! Invalid!")
		return null
	response = _EncodeIntArray(response)	
	var stunMsg = StunMessage.new()
	stunMsg.first32bit = response[0]
	stunMsg.type = response[0] & Type.BITS
	stunMsg.method = response[0] & Method.BITS
	stunMsg.length = response[0] & Format.MESSAGE_LENGTH
	stunMsg.magicCookie = response[1]
	stunMsg.transactionID = response.slice(2, 4)
	#print("received transaction id: " + str(stunMsg.transactionID))
	stunMsg.attributes = _ExtractAttributes(response.slice(5, response.size()-1))
	return stunMsg


func _GetXORMappedAddress(attribute, response: StunMessage):
	var family	= attribute[0] & Attribute.MAPPED_ADDRESS_FML
	#print("xport before: " + str((attribute[0] &  Attribute.MAPPED_ADDRESS_PORT)))
	var xport	= (attribute[0] ^ Attribute.XOR_COOKIE) & Attribute.MAPPED_ADDRESS_PORT
	#print("xport after: " + str(xport))
	var xaddress= attribute.slice(1, attribute.size()-1, 1, true)

	#print("xaddress before: " + str(xaddress))
	var xor_block = [Format.MAGIC_COOKIE,
					 response.transactionID[0],
					 response.transactionID[1],
					 response.transactionID[2]]
					
	for i in range(0, xaddress.size()):
		xaddress[i] ^= xor_block[i]
		
	#print("xaddress after: " + str(xaddress))
	
	var resolved_address = _ConvertIPValueToString(family, xaddress)
	
	# TODO: WARN: Closing socket here might causes a problem later on when we forget it
	# As long as we only use this for XOR MAPPED ADDRESS, I guess it'll be fine
	# Close socket before Menu or Lobby could setup server
	_CloseSocket()
	
	emit_signal("external_address_resolved", resolved_address, xport)


# Convert ip_value to String representation
# @ip_type is Attribute.MAPPED_ADDRESS_IPvF or Attribute.MAPPED_ADDRESS_IPvS
# @ip_value is an Array of ints. 
# 1 int for Attribute.MAPPED_ADDRESS_IPvF 
# 4 ints for Attribute.MAPPED_ADDRESS_IPvS 
# TODO: Untested
const EQUIVALENT_HEX = "0123456789abcdef"
func _ConvertIPValueToString(ip_type, ip_value):
	var result = ""
	if ip_type == Attribute.MAPPED_ADDRESS_IPvF:
		print ("IPv4: " + str(ip_value[0]))
		for i in range(24, -8, -8):
			result += str((ip_value[0] >> i) & 0xFF) + "."
		result.erase(result.length() - 1, 1)
		return result
		
	elif ip_type == Attribute.MAPPED_ADDRESS_IPvS:
		#print ("IPv6: " + str(var2bytes(ip_value)))
		for fourBytes in ip_value:
			for halfByte in range(28, -4, -4):
				result += EQUIVALENT_HEX[(fourBytes >> halfByte) & 0xF]
		#TODO: Insert without copying
		for colon_pos in range(28, 0, -4):
			result = result.insert(colon_pos, ":")
		return _shortifyIPvS(result)
		
	else:
		printerr("Unknown ip_type: \"" + str(ip_type) + "\"")
		return "???Unknown ip type???"


#TODO:
func _shortifyIPvS(ipvs):
	return ipvs


# Return an array of entries.
# Each entry is in the form [TYPE, CONTENT]
# LENGTH is omitted, as it's already stored in the array CONTENT
func _ExtractAttributes(response: Array):
	var results = []
	var read_head = 0
	while read_head < response.size():
		var length = response[read_head] & Attribute.LENGTH
		results.push_back([response[read_head] & Attribute.TYPE,\
							response.slice(read_head + 1, read_head + 1 + length)])
		read_head = read_head + 1 + length
	return results


# Return true if this is the response to STUN request
# TODO: Check attributes validity
func _IsValid(response: StunMessage):
	return response.first32bit & Format.ZEROES_PREFIX == 0 and\
		response.magicCookie == Format.MAGIC_COOKIE and\
		response.transactionID == _lastTransactionID


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
	#pass


func _on_RFC8489_STUN_time_out():
	_CloseSocket()
