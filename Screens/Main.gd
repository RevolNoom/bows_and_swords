extends Node

var _tcp
var _udp = PacketPeerUDP.new()
var _udps = PacketPeerUDP.new()

var _timer
var _ip
var _port

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	Menu.visible = true
	#Menu.visible = false
	#$RFC8489_STUN.GetExternalAddress(1025)
	#TryTCP()


func TryUDP(ip, port):
	_udp.listen(1025)
	_udps.connect_to_host(ip, port)
	_udps.put_packet(var2bytes("Hi"))
	#_udps.set_dest_address(ip, port)
	
	
func _process(delta):
	if _udp.get_available_packet_count() > 0:
		print(_udp.get_packet())
	else:
		if not _udps.is_connected_to_host():
			print("_udps not connected")
			_udps.connect_to_host(_ip, _port)
		_udps.put_packet(var2bytes("Hi"))
		#print("Sent at " + str(Time.get_ticks_msec()))
	

func TryTCP():
	_tcp = TCP_Server.new()
	var port = 1026
	var bind_addr = "192.168.55.109"
	if _tcp.listen(port, bind_addr) != OK:
		print("Error listening on port " + str(port) + " of " + bind_addr)
		return
		
	_timer = get_tree().create_timer(1)
	_timer.connect("timeout", self, "TryGetConnection")


func TryGetConnection():
	var connection = _tcp.take_connection()
	if connection != null:
		print("Took a connection? " + str(connection.is_connected_to_host()))
	else:
		print("Still listening")
	_timer = get_tree().create_timer(1)
	_timer.connect("timeout", self, "TryGetConnection")


func _on_RFC8489_STUN_external_address_resolved(ip, port):
	print("Binding: " + str(ip) + ":" + str(port))
	print(ip)
	_ip = ip
	_port= port
	TryUDP(ip, port)
	var timer = get_tree().create_timer(0.1)
	timer.connect("timeout", self, "NATPunch")

func NATPunch():
	var timer = get_tree().create_timer(0.1)
	timer.connect("timeout", self, "NATPunch")

	if _udp.get_available_packet_count() > 0:
		print(_udp.get_packet())
	else:
		if not _udps.is_connected_to_host():
			print("_udps not connected")
			_udps.connect_to_host(_ip, _port)
		_udps.put_packet(var2bytes("Hi"))
