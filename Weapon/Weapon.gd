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
	add_collision_exception_with(player)
	$Hitbox.add_collision_exception_with(player)
	var mastery = _handler.GetAttribute("Mastery").value
	
	
# NOTE: Modifying global transform work
# But state.transform does not
# TODO: Move Weapon in addition to Dummy correcting motion
func _integrate_forces(_state):
	var mastery = _handler.GetAttribute("Mastery").value
	applied_force = $Stabilize.Position($Stabilize.global_position, _handlePoint.global_position) * mastery
	applied_torque = $Stabilize.Rotation($Stabilize.global_rotation, _handler.global_rotation) * mastery
	#TODO: Take into account the absolute displacement of weapon


func _on_handler_die(_body):
	visible = false
	call_deferred("set_collision_layer", 0)
	call_deferred("set_collision_mask", 0)
	
	$Hitbox.call_deferred("set_collision_layer", 0)
	$Hitbox.call_deferred("set_collision_mask", 0)
	
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



