extends Node2D

class_name Map

func LoadPlayers():
	_players.clear()
	var spawnpoint = 1
	var players = Menu.GetLobby().GetRoom().GetPlayerEntries()
	for entry in players:
		var player
		if int(entry.name) == get_tree().get_network_unique_id():
			player = preload("res://Player/Player.tscn").instance()
		else:
			player = preload("res://Player/Dummy.tscn").instance()
			
		player.name = entry.name
		player.set_network_master(int(entry.name))
		
		_players.append(player)
		$SpawnPoint.get_node(str(spawnpoint)).add_child(player)
		spawnpoint += 1


func get_players():
	return _players


func get_player(network_id):
	for player in _players:
		if player.get_network_master() == network_id:
			return player
	
	
var _players = []
