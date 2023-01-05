#extends KinematicBody2D
extends RigidBody2D

class_name Dummy

signal die(dummy)

	
# Called when the node enters the scene tree for the first time.
func _ready():
	var dontcare = GetAttribute("Health").connect("empty", self, "Die", [], CONNECT_ONESHOT)
	EquipWeapon(load("res://Weapon/Sword/Sword.tscn").instance())
	

func _integrate_forces(_state):
	#print($RotationController.GetRange())
	applied_torque = $RotationController.GetSpinFactor()*GetAttribute("Agility").value
									
	
func GetAttribute(name):
	return $Attribute.get_node(name)


func EquipWeapon(weapon):
	
	if $RightHand.get_child_count() > 0:
		var wp = $RightHand.get_child(0)
		remove_child(wp)
		wp.queue_free()
		
	weapon.add_collision_exception_with(self)
	weapon.HandledBy(self)
	$RightHand.add_child(weapon)
	

# DAMAGING FUNCTIONS
# Deal damage to Health, inversely proportional to Armor
func TakeDamagePhysical(amount, piercing := 0):
	_TakeDamage("Health", amount, GetAttribute("Armor").value, piercing)


func _TakeDamage(attribute_name, amount, defense_value, piercing):
	GetAttribute(attribute_name).Reduce(amount * (100 + piercing) / (100 + defense_value))


#func Heal(amount):
#	GetAttribute("Health").Add(amount)


# MISC

func IsAlive():
	return GetAttribute("Health").value == 0


func Die():
	visible = false
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	emit_signal("die", self)
	
	
# Subclass sandbox
remotesync func UpdatePosture(newGPosition, newGRotation):
	global_position = newGPosition
	global_rotation = newGRotation
