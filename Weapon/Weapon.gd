#extends KinematicBody2D
#extends Area2D
extends RigidBody2D

class_name Weapon

var _handler


func _ready():
	$Handle.add_collision_exception_with(self)
	
	
func HandledBy(player):
	_handler = player
	var mastery = _handler.GetAttribute("Mastery").value
	$Handle.add_collision_exception_with(player)
	
# NOTE: Modifying global transform work
# But state.transform does not
func _integrate_forces(_state):
	var mastery = _handler.GetAttribute("Mastery").value
	applied_force = $Stabilizer.StabilizeDisplacement(self, get_parent()) * mastery
	applied_torque = $Stabilizer.StabilizeAngle(self, _handler) * mastery
	# _restrictAngleBias()


func _on_Weapon_body_entered(body):
	_tryHitDummy(body)


func _process(delta):
	for object in get_colliding_bodies():
		_tryHitDummy(object)


func _tryHitDummy(object):
	var current_time = Time.get_ticks_msec()
	if object is Dummy and _hit_cooldown.get(object, 0) + $HitCooldown.value < current_time:
		object.TakeDamagePhysical($Damage.value, $Piercing.value)
		_hit_cooldown[object] = current_time
	

# HitCooldown: Minimal interval between two damaging hits
# prevents the case when a weapon emits body_entered rapidly.
var _hit_cooldown = {}


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

