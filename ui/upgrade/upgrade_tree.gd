extends ColorRect

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("ui_drag"):
		global_position += event.relative
