extends Node

# An array of [linear_velocity, angular_velocity, pos, rot]
var _puppetState = null
func UpdateState(body):
	# TODO: A float???
	rpc("_updateState", [body.linear_velocity, body.angular_velocity, body.global_position, body.global_rotation])


puppet func _updateState(new_puppet_state):
	_puppetState = new_puppet_state
	call_deferred("_syncMasterState")
	

const POSITION_CORRECT_THRESHOLD = 40
const ROTATION_CORRECT_THRESHOLD = PI/20
# Call only from _integrate_forces (???)
# Sparingly modify position and rotation 
# as modifying too often could ruin physic simulation
func _syncMasterState():
	if _puppetState != null:
		if (get_parent().global_position - _puppetState[2]).length() > POSITION_CORRECT_THRESHOLD:
			get_parent().global_position = _puppetState[2]
			get_parent().linear_velocity = _puppetState[0]
			
		if (get_parent().rotation - _puppetState[3]) > ROTATION_CORRECT_THRESHOLD:
			get_parent().global_rotation = _puppetState[3]
			get_parent().angular_velocity = _puppetState[1]
		
		_puppetState = null
	
