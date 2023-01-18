#extends KinematicBody2D
extends RigidBody2D

class_name Dummy

signal die(dummy)

	
# Called when the node enters the scene tree for the first time.
func _ready():
	#var dontcare = GetAttribute("Health").connect("empty", self, "Die", [], CONNECT_ONESHOT)
	
	#EquipWeapon(load("res://Weapon/Sword/Sword.tscn").instance())
	EquipWeapon(load("res://Weapon/Spear/Spear.tscn").instance())
	#EquipWeapon(load("res://Weapon/Pike/Pike.tscn").instance())
	
	$Stabilize.displacement_strength = GetAttribute("Speed").value
	
	# 1.5 to speed up angular lag because of network latency
	# Actually, removed because it takes too long to converge to master state
	$Stabilize.angular_strength = GetAttribute("Agility").value * 2 
	
	# Initiallize Master state. Or else puppets will swing uncontrollably
	# when the game starts in other clients
	UpdateState(Vector2(), 0, global_position, global_rotation, global_rotation)
	


puppet func UpdateState(linearVelocity, angularVelocity, pos, rot, target_rot):
	$Attribute/NetworkMasterState.linear_velocity = linearVelocity
	$Attribute/NetworkMasterState.global_position = pos
	$Attribute/NetworkMasterState.global_rotation = rot
	$Attribute/NetworkMasterState.angular_velocity = angularVelocity
	_target_rotation = target_rot


const POSITION_CORRECT_THRESHOLD = 200
const ROTATION_CORRECT_THRESHOLD = PI/5
var _target_rotation = 0

func _integrate_forces(state):
	if $Stabilize.AngularDifference(global_rotation, $Attribute/NetworkMasterState.global_rotation) > ROTATION_CORRECT_THRESHOLD:
		global_rotation = $Attribute/NetworkMasterState.global_rotation
		angular_velocity = $Attribute/NetworkMasterState.angular_velocity
	
	if (global_position - $Attribute/NetworkMasterState.global_position).length() > POSITION_CORRECT_THRESHOLD:
		global_position = $Attribute/NetworkMasterState.global_position
		linear_velocity = $Attribute/NetworkMasterState.linear_velocity	
	
	applied_force = $Stabilize.Position(global_position, $Attribute/NetworkMasterState.global_position)
	applied_torque = $Stabilize.Rotation(global_rotation, _target_rotation)
	

func GetAttribute(name):
	return $Attribute.get_node(name)


func EquipWeapon(weapon):
	if $RightHand.get_child_count() > 0:
		var wp = $RightHand.get_child(0)
		remove_child(wp)
		wp.queue_free()
	
	connect("die", weapon, "_on_handler_die")
	weapon.HandledBy(self, $RightHand)
	
	$RightHand.add_child(weapon)
	weapon.global_position = $RightHand.global_position
	#print(str(get_path()) + " position: " + str(global_position))
	#print(str(weapon.get_path()) + " position: " + str(weapon.global_position))
	#print()


# DAMAGING FUNCTIONS
# Deal damage to Health, inversely proportional to Armor
master func TakeDamagePhysical(amount, piercing := 0):
	rpc("_TakeDamage", "Health", amount, GetAttribute("Armor").value, piercing)
	_TakeDamage("Health", amount, GetAttribute("Armor").value, piercing)


puppet func _TakeDamage(attribute_name, amount, defense_value, piercing):
	GetAttribute(attribute_name).Reduce(amount * (100 + piercing) / (100 + defense_value))


#func Heal(amount):
#	GetAttribute("Health").Add(amount)


# MISC

func IsAlive():
	return GetAttribute("Health").value == 0


func _on_Agility_value_changed(value):
	$Stabilize.angular_strength = value


func _on_Speed_value_changed(value):
	$Stabilize.displacement_strength = value


func _on_Health_empty():
	visible = false
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	emit_signal("die", self)
	pass # Replace with function body.
