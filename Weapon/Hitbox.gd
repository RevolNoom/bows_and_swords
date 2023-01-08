extends RigidBody2D

func _ready():
	set_process(false)


func _on_Hitbox_body_entered(_body):
	set_process(true)


func _process(_delta):
	for object in get_colliding_bodies():
		var current_time = Time.get_ticks_msec()
		if _hit_cooldown.get(object, 0) + $HitCooldown.value < current_time:
			object.TakeDamagePhysical($Damage.value, $Piercing.value)
			_hit_cooldown[object] = current_time
			

func _on_Hitbox_body_exited(_body):
	if get_colliding_bodies().size() == 0:
		set_process(false)

# HitCooldown: Minimal interval between two damaging hits
# prevents the case when a weapon emits body_entered rapidly.
var _hit_cooldown = {}
