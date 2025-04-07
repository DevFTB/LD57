extends ColorRect
class_name UpgradeTree

var initial_pos : Vector2

func _ready() -> void:
	initial_pos = global_position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("ui_drag"):
		global_position += event.relative
