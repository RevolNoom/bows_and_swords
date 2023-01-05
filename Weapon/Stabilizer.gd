extends Node2D

export(float) var displacement_band_width = 10.0
export(float) var displacement_strength = 0.01
export(float) var displacement_safe_bands = 1

export(float) var angular_bands = 3.0
export(float) var angular_strength = 0.01
export(float) var angular_safe_bands = 1

func StabilizeDisplacement(node_from, node_to):
	var displacement = node_to.global_position - node_from.global_position
	var band = ceil(displacement.length() / displacement_band_width) - displacement_safe_bands
	return clamp(band, 0, band) * displacement.normalized() * displacement_strength

func StabilizeAngle(node_from, node_to):
	var displacement = node_to.global_rotation - node_from.global_rotation
	if displacement > PI:
		displacement -= 2*PI
	elif displacement < -PI:
		displacement += 2*PI
		
	var band = int(displacement * angular_bands / PI)
	if band < 0:
		band = clamp (band + angular_safe_bands - 1, band, 0)
	else:
		band = clamp (band - angular_safe_bands + 1, 0, band)
	return band * angular_strength 
