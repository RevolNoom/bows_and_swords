extends LobbyRoom


func _ready():
	_entryScene = {
	"Host": preload("res://Screens/Menu/Lobby/Guest/HostEntry.tscn"),
	"Guest": preload("res://Screens/Menu/Lobby/Guest/GuestEntry.tscn"),
	"You": preload("res://Screens/Menu/Lobby/Guest/YouEntry.tscn")
	}
	get_tree().connect("connected_to_server", self, "_on_Network_server_connected")
	get_tree().connect("server_disconnected", self, "_on_Network_server_disconnected")


func SetupClient(player_name, ip, port):
	if port is String:
		port = int(port)
		
	var client = NetworkedMultiplayerENet.new()
	var err = client.create_client(ip, port)
	if err != OK:
		emit_signal("error", "Can't connect to " + str(ip) + ":" + str(port))
		return
		
	get_tree().network_peer = client
	
	_youEntry = _entryScene["You"].instance()
	_youEntry.set_name(player_name)
	_youEntry.connect("exit_pressed", self, "_on_You_exit")
	_youEntry.connect("move", self, "_on_You_move")
	$Queue/WaitQueue.add_child(_youEntry)


func _on_Network_server_disconnected():
	for queue in [$Queue/WaitQueue, $Room/PlayQueue]:
		for entry in queue.get_children():
			queue.remove_child(entry)
			entry.free()


func _on_Network_server_connected():
	_youEntry.name = str(get_tree().get_network_unique_id())
	#_youEntry.set_network_master(get_tree().get_network_unique_id())


func _on_Launch_toggled(button_pressed):
	_youEntry.rpc("set_status", "READY" if button_pressed\
								else "PREPARING")


func _on_You_move(_entry):
	# Switch back and forth between states
	$Room/Controller/State/Launch.disabled = not $Room/Controller/State/Launch.disabled 
	$Room/Controller/State/Launch.set_pressed_no_signal(false)


remotesync func InitializeGame():
	.InitializeGame()
	$Room/Controller/State/Launch.disabled = true
	

func _DoResetRoomOnAllPlayersLeaveGameplay(entry):
	if not all_players_have_left_gameplay():
		return
		
	._DoResetRoomOnAllPlayersLeaveGameplay(entry)
	
	$Room/Controller/State/Launch.disabled = false
	$Room/Controller/State/Launch.pressed = false
	
	
# At end game, lock launching until all players are not in Gameplay anymore
# TODO
#func _on_Gameplay_end_game():
#	$Room/Controller/State/Launch.disabled = true


func _on_RFC8489_STUN_external_address_resolved(_ip, _port):
	pass # Replace with function body.


func _on_RFC8489_STUN_time_out():
	pass # Replace with function body.
