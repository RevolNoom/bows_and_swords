extends Node2D

export var _rangeCount = 5

# Return the spin direction and strength
# determined from how far the mouse has diverged from line of sight
func GetSpinFactor():
	var mouse_angle = get_local_mouse_position().angle()
	var sectionMouseFallIn = mouse_angle/2/PI * _rangeCount
	if _rangeCount % 2 == 1:
		return round(sectionMouseFallIn)
	return floor(sectionMouseFallIn) + int(mouse_angle < 0) 
	
	
