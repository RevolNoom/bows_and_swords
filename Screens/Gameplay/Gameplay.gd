extends Node2D

signal end_game


func _on_MainMenuButton_pressed():
	BackToLobby()


func _on_player_die(player):
	_playerLeft.erase(player)
	if player.name ==  str(get_tree().get_network_unique_id()):
		ShowResultScreen("You Lose")
	elif _playerLeft.size() == 1 and _playerLeft[0].name == str(get_tree().get_network_unique_id()):
		ShowResultScreen("You Win")
		rpc("EndMatch")
		

func Initialize():
	visible = true
	var map = preload("res://Maps/Colosseum/Colosseum.tscn").instance()
	map.name = "Map"
	add_child(map)
	get_node("Map").LoadPlayers()
	$Dump.Clear()
	_playerLeft = $Map.get_players()
	for player in $Map.get_players():
		player.connect("die", self, "_on_player_die")
	
	$CanvasLayer/HUD.DisplayFor(get_node("Map").get_player(get_tree().get_network_unique_id()))
	$CanvasLayer.visible = true


func BackToLobby():
	Menu.GetLobby().GetRoom().GetEntry(get_tree().get_network_unique_id()).rpc("set_status", "WATCHING")
	Menu.visible = true
	visible = false
	
	var map = $Map 
	remove_child(map)
	map.queue_free()
	$CanvasLayer.visible = false


func ShowResultScreen(resultLine):
	$CanvasLayer/CenterContainer/VBox/GameResult.text = resultLine
	$CanvasLayer.visible = true
	

remotesync func EndMatch():
	$CanvasLayer/CenterContainer/VBox/ToLobbyNotice.Start()
	emit_signal("end_game")
	
	
var _playerLeft
