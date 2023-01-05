extends HBoxContainer
# TODO: Shows pop up when server disconnect 
# TODO: Shows pop up when server kicks player out


func GetRoom():
	return get_node("Room")
	
	
func _on_LobbyDecision_host(player_name, port):
	var room = preload("res://Screens/Menu/Lobby/Host/HostRoom.tscn").instance()
	switch_to_room(room)
	room.SetupServer(player_name, port)


func _on_LobbyDecision_join(player_name, ip, port):
	var room = preload("res://Screens/Menu/Lobby/Guest/GuestRoom.tscn").instance()
	switch_to_room(room)
	room.SetupClient(player_name, ip, port)
	
	
func switch_to_room(room):
	add_child(room)
	$LobbyDecision.hide()
	room.name = "Room"
	room.connect("exit", self, "_on_Room_exit")


func _on_Room_exit():
	$LobbyDecision.show()
	get_node("Room").queue_free()
	


