extends Position2D

#TODO: Merge the logic into SpellWheel

# Each SpellSlot fits a 32px radius circle. 
# Any spell icon should follow this size


func RefersTo(newSpell: Spell):
	FlushSpell()
	newSpell.connect("mouse_entered", self, "_on_mouse_entered")
	newSpell.connect("mouse_exited", self, "_on_mouse_exited")
	add_child(newSpell)
	

# Two Signals to work-around a problem
# SpellWheel can intercept InputEventMouseButton
# but SpellSlot loses it
# I don't know why the click is not propagated to this button
# even though it can intercept MouseMotion
#func _on_Button_input_event(_viewport, event, _shape_idx):
#	print("Button" + str(event))
#	if event is InputEventMouseButton:
#		if event.pressed == false:
#			print("SetSpell")
	
	
func FlushSpell():
	_isHoveredOn = false
	for spell in get_children():
		#print("Flushed: " + spell.name)
		spell.disconnect("mouse_entered", self, "_on_mouse_entered")
		spell.disconnect("mouse_exited", self, "_on_mouse_exited")
		remove_child(spell)
		

func GetSpell():
	return get_children()[0]


func IsChosen():
	if _isHoveredOn:
		return true
	return false
	

var _isHoveredOn
func _on_mouse_entered():
	_isHoveredOn = true
	
func _on_mouse_exited():
	_isHoveredOn = false
