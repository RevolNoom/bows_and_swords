extends HBoxContainer

class_name LobbyRoom

signal exit()


var _youEntry
var _entryScene = {
	"Host": null,
	"Guest": null,
	"You": null
}


func _ready():
	Gameplay.connect("end_game", self, "_on_Gameplay_end_game")
	
	# Connect after network setup
	get_tree().connect("network_peer_connected", self, "_on_Network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_Network_peer_disconnected")
	

# Send our information over the network
func _on_Network_peer_connected(id):
	rpc_id(id, "CreateEntry", [get_tree().get_network_unique_id()\
							, get_path_to(_youEntry.get_parent())\
							, _youEntry.get_name()\
							, _youEntry.get_status()])


func _on_Network_peer_disconnected(id):
	for queue in [$Queue/WaitQueue, $Room/PlayQueue]:
		var entry = queue.get_node_or_null(str(id))
		if entry != null:
			queue.remove_child(entry)
			entry.free()


func GetEntry(network_id):
	for entry in [$Queue/WaitQueue.get_node_or_null(str(network_id))\
				, $Room/PlayQueue.get_node_or_null(str(network_id))]:
		if entry != null:
			return entry
			

func GetPlayerEntries():
	return $Room/PlayQueue.get_children()


# Entry info is stored in an array:
# @0: Sender ID. To distinguishes between host and guests
# @1: Path to wait or play queue
# @2: Player name
# @3: Status ("PLAYING", "WAITING", ...)
# @return: Handle to the created entry, that has been appended to a parent node
remote func CreateEntry(entry_info):
	var id = entry_info[0]
	var role = "Host" if id == 1 else\
				"You" if id == get_tree().get_network_unique_id() \
					else "Guest"
	var parent = get_node(entry_info[1])
	var pname = entry_info[2]
	var status = entry_info[3]
	
	var entry = _entryScene[role].instance()
	#entry.set_network_master(id)
	entry.name = str(id)
	#entry.set_role(role) # No need, info already saved in scene
	entry.set_name(pname)
	entry.set_status(status)
	
	parent.add_child(entry)
	return entry


func _on_You_exit(_entry):
	get_tree().network_peer = null
	emit_signal("exit")
	
	
func _on_Entry_exit(entry):
	entry.queue_free()
	

func _on_Entry_exit_pressed(entry):
	entry.rpc("Exit")
	
	
func _on_Entry_move_pressed(entry):
	if entry.get_parent() == $Queue/WaitQueue:
		rpc("ChangeQueue", entry.get_path(), $Room/PlayQueue.get_path(), "PREPARING")
	else:
		rpc("ChangeQueue", entry.get_path(), $Queue/WaitQueue.get_path(), "WAITING")


# @0: Entry path
# @1: Destination path
# @2: New Status
remotesync func ChangeQueue(entry_path, destination_path, new_status):
	var entry = get_node(entry_path)
	entry.set_status(new_status)
	entry.MoveTo(get_node(destination_path))
	
	
remotesync func InitializeGame():
	for player in $Room/PlayQueue.get_children():
		player.set_status("PLAYING")
		
	if _youEntry.get_parent() == $Room/PlayQueue:
		Menu.visible = false
		Gameplay.Initialize()


# At end game, lock launching until all players are not in Gameplay anymore
# TODO
func _on_Gameplay_end_game():
	#$Room/Controller/State/Launch.disabled = true
	for entry in $Room/PlayQueue.get_children():
		entry.connect("status_changed", self, "_DoResetRoomOnAllPlayersLeaveGameplay")
	
	
func _DoResetRoomOnAllPlayersLeaveGameplay(_entry):
	
	if not all_players_have_left_gameplay():
		return

	for entry in $Room/PlayQueue.get_children():
		entry.disconnect("status_changed", self, "_DoResetRoomOnAllPlayersLeaveGameplay")

		# Remove disconnected players
		if entry.get_status() == "DISCONNECTED":
			entry.ExitTree()

		else: # Reset players' statuses
			entry.set_status("PREPARING")
			
	# Reset players' statuses
	for entry in $Queue/WaitQueue.get_children():
		entry.set_status("WAITING")


func all_players_have_left_gameplay():
	for entry in $Room/PlayQueue.get_children():
		if entry.get_status() == "PLAYING":
			return false
	return true
