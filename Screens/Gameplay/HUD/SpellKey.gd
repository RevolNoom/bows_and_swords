extends TextureButton
# TODO: Currently useless, should be used for mobile GUI

export var _keyBinding = ""


func _unhandled_key_input(event):
	if event.pressed and event.scancode == ord(_keyBinding):
		get_tree().set_input_as_handled()
		emit_signal("pressed")
