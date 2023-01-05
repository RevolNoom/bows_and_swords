extends Control
	
	
func DisplayFor(player):
	if _displayedPlayer != null and _displayedPlayer.is_instance_valid():
		_displayedPlayer.GetAttribute("Health").unshare()
		_displayedPlayer.GetAttribute("Focus").unshare()
		_displayedPlayer.GetAttribute("Mana").unshare()
		#$Bottom/SpellSlot.disconnect("cast_spell", _displayedPlayer, "_on_HUD_cast_spell")
	
	_displayedPlayer = player
	
	for attribute in $Top/Margin/Attributes/Dynamic.get_children()\
					+$Top/Margin/Attributes/Static.get_children():
		attribute.Display(player.GetAttribute(attribute.name))

	#var ignore_err = $Bottom/SpellSlot.connect("pressed", player, "_on_HUD_cast_spell")


var _displayedPlayer
