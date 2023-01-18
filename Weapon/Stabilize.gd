extends Node2D

export(float) var displacement_band_width = 10.0
export(float) var displacement_strength = 0.01
export(float) var displacement_safe_bands = 1.0


export(float) var angular_bands = 3.0
export(float) var angular_strength = 0.01
export(float) var angular_safe_bands = 1.0



func Position(from_gpos, to_gpos):
	var displacement = to_gpos - from_gpos
	var band = ceil(displacement.length() / displacement_band_width) - displacement_safe_bands
	return clamp(band, 0, band) * displacement.normalized() * displacement_strength


func Rotation(from_grot, to_grot):
	var angle_diff = AngularDifference(to_grot, from_grot)
		
	var band = int(angle_diff * angular_bands / PI)
	if band < 0:
		band = clamp (band + angular_safe_bands - 1, band, 0)
	else:
		band = clamp (band - angular_safe_bands + 1, 0, band)
	return band * angular_strength 


# Return to_angle - base_angle without being rounded-about
func AngularDifference(to_angle, base_angle):
	var diff = to_angle - base_angle
	return diff - 2*PI if diff > PI else diff + 2*PI if diff < -PI else diff
