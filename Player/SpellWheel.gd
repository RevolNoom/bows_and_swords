extends Node2D

signal spell_chosen(spell)

func _ready():
	_spellBookCopy = Menu.GetSpellBook().GetSpells()
	
	for i in range(_spellBookCopy.size()):
		_spellBookCopy[i] = _spellBookCopy[i].duplicate()
		_spellBookCopy[i].visible = true
	
	for slot in get_children():
		var spell = _spellBookCopy.pop_front()
		slot.RefersTo(spell)


# Burn the spell book
func _exit_tree():
	for slot in get_children():
		var spell = slot.get_child(0)
		slot.remove_child(spell)
		spell.free()
	for spell in _spellBookCopy:
		spell.free()


var _isHolding = false
func _unhandled_input(event):
	if event is InputEventMouseButton:
		_isHolding = event.pressed
		global_position = event.global_position
	
	if not visible and _isHolding and event is InputEventMouseMotion :
		OpenWheel()
	
	elif visible and not _isHolding:
		CloseWheel()
		for slot in get_children():
			if slot.IsChosen():
				emit_signal("spell_chosen", slot.GetSpell())


func PopSpellOffWheel(spell):
	var slot = spell.get_parent()
	slot.RefersTo(_spellBookCopy.pop_front())
	_spellBookCopy.push_back(spell)
	

func OpenWheel():
	visible = true
	
	
func CloseWheel():
	visible = false


func Disable():
	CloseWheel()
	set_process_unhandled_input(false)
	
	
func Enable():
	set_process_unhandled_input(true)
	

var _spellBookCopy
