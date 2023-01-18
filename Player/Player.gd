extends Dummy

#func _ready():
	#var ignore_err = connect("die", self, "_on_Player_die")

func _integrate_forces(_state):
	var velo = Vector2()
	
	if Input.is_action_pressed("ui_left"):
		velo.x = -1
	if Input.is_action_pressed("ui_right"):
		velo.x = 1
		
	if Input.is_action_pressed("ui_up"):
		velo.y = -1
	if Input.is_action_pressed("ui_down"):
		velo.y = 1

	applied_torque = $Stabilize.Rotation(0, get_local_mouse_position().angle())
	applied_force = velo.normalized()*GetAttribute("Speed").value
	
	
	rpc("UpdateState", linear_velocity, angular_velocity, global_position, global_rotation, (get_global_mouse_position() - global_position).angle())


#func _on_Player_die(_self):
	# TODO: Stop Player's regen?
	#pass
