extends GuestEntry


func _ready():
	connect("move", self, "_on_self_move")
	
	
func _on_self_move(_entry):
	$Move.disabled = not $Move.disabled
