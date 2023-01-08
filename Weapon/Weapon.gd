#extends KinematicBody2D
#extends Area2D
extends RigidBody2D

class_name Weapon

var _handler
var _handlePoint


func _ready():
	$Hitbox.add_collision_exception_with(self)
	
	
func HandledBy(player, handle_point):
	_handler = player
	_handlePoint = handle_point
	var mastery = _handler.GetAttribute("Mastery").value
	add_collision_exception_with(player)
	$Hitbox.add_collision_exception_with(player)
	
	
# NOTE: Modifying global transform work
# But state.transform does not
func _integrate_forces(_state):
	var mastery = _handler.GetAttribute("Mastery").value
	applied_force = $Stabilizer.StabilizeDisplacement($Stabilizer, _handlePoint) * mastery
	applied_torque = $Stabilizer.StabilizeAngle($Stabilizer, _handler) * mastery
	# _restrictAngleBias()


# UNUSED
#const angle_restrict = PI/2
#func _restrictAngleBias():
#	var angle_bias = _handler.global_rotation - global_rotation
#	if angle_bias > PI:
#		angle_bias -= 2*PI
#	elif angle_bias < -PI:
#		angle_bias += 2*PI
#	if abs(angle_bias) > angle_restrict:
#		angle_bias = clamp(angle_bias, -angle_restrict, angle_restrict)
#		global_rotation = _handler.global_rotation - angle_bias



