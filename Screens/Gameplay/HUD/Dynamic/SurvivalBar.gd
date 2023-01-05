extends CenterContainer

func Display(attribute):
	attribute.share($TextureProgress)

func _on_TextureProgress_changed():
	$TextureProgress/HBox/MaxValue.text = str(round($TextureProgress.max_value))


func _on_TextureProgress_value_changed(value):
	$TextureProgress/HBox/Value.text = str(round(value))
