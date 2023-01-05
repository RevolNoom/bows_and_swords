extends CenterContainer

signal host(player_name, port)
signal join(player_name, ip, port)

export var DEFAULT_PORT = 7979

func _ready():
	seed(OS.get_unix_time())
	var pname = ""
	for i in range(0, 5):
		pname += char(ord("a") + randi() %(ord("z")-ord("a")))
	$HBox/VBox/HBox/Name.text = pname
	$HBox/VBox/Host_Join/Info/Address/ClientPort.text = str(DEFAULT_PORT)
	$HBox/VBox/Host_Join/Info/ServerPort.text = str(DEFAULT_PORT)


func PopupErrMsg(msg):
	$HBox/VBox/Popup/Errmsg.text = msg
	$HBox/VBox/Popup.popup()
	
	
func _on_Host_pressed():
	var player_name = $HBox/VBox/HBox/Name.text
	if player_name == "":
		PopupErrMsg("Please fill in your name!")
		return
		
	var port = $HBox/VBox/Host_Join/Info/ServerPort.text 
	if port == "":
		PopupErrMsg("Please fill in the port you want to host the game!")
		return

	emit_signal("host", player_name, int(port))


func _on_Join_pressed():
	var player_name = $HBox/VBox/HBox/Name.text
	if player_name == "":
		PopupErrMsg("Please fill in your name!")
		return
	
	var ip = $HBox/VBox/Host_Join/Info/Address/IP.text
	if ip == "":
		PopupErrMsg("Please fill in your friend's IP address!")
		return
	
	var port = $HBox/VBox/Host_Join/Info/Address/ClientPort.text 
	if port == "":
		PopupErrMsg("Please fill in your friend's port!")
		return
		
	emit_signal("join", player_name, ip, int(port))
