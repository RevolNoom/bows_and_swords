# This node contains all things that should be forgotten
# e.g.: projectiles, effects,...

extends Node

func Add(projectile):
	projectile.z_index = 1
	add_child(projectile)\
	
	
func Clear():
	for anything in get_children():
		anything.queue_free()
