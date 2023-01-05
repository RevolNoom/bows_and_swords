extends HBoxContainer

func Display(attribute):
	if _displayedAttribute != null and _displayedAttribute.is_instance_valid():
		_displayedAttribute.disconnect("value_changed", self, "_on_Attribute_value_changed")
	_displayedAttribute = attribute
	attribute.connect("value_changed", self, "_on_Attribute_value_changed")
	_on_Attribute_value_changed(attribute.value)


func _on_Attribute_value_changed(value):
	$Amount.text = str(round(value))


var _displayedAttribute
