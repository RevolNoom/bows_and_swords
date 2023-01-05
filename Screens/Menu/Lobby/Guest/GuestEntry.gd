extends HBoxContainer

class_name GuestEntry

signal exit(self_entry)
signal exit_pressed(self_entry)
signal move(self_entry)
signal move_pressed(self_entry)
signal status_changed(self_entry)


func get_role():
	return $Role.text
remotesync func set_role(new_role):
	$Role.text = new_role

func get_name():
	return $Name.text 
remotesync func set_name(new_name):
	$Name.text = new_name


func get_status():
	return $Status.text
remotesync func set_status(new_status):
	$Status.text = new_status
	emit_signal("status_changed", self)


func MoveTo(new_node):
	get_parent().remove_child(self)
	new_node.add_child(self)
	emit_signal("move", self)


func ExitTree():
	get_parent().remove_child(self)
	emit_signal("exit")


func _on_Move_pressed():
	emit_signal("move_pressed", self)


func _on_Exit_pressed():
	emit_signal("exit_pressed", self)
