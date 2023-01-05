extends Dummy

func _ready():
	var ignore_err = connect("die", self, "_on_Player_die")

func _integrate_forces(state):
	._integrate_forces(state)
	var velo = Vector2()
	
	if Input.is_action_pressed("ui_left"):
		velo.x = -1
	if Input.is_action_pressed("ui_right"):
		velo.x = 1
		
	if Input.is_action_pressed("ui_up"):
		velo.y = -1
	if Input.is_action_pressed("ui_down"):
		velo.y = 1
	
	applied_force = velo.normalized()*GetAttribute("Speed").value
	#state.linear_velocity = velo
	
	

#func _process(_delta):
#	rpc("UpdatePosture", global_position, global_rotation)



func _on_Player_die(_self):
	# TODO: Stop Player's regen?
	pass
