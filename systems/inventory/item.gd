extends Resource
class_name Item

@export var id: StringName
@export var display_name: String
@export var texture: Texture2D

func _init(p_id: StringName = "default", p_display_name: String = "Item", p_texture: Texture2D = null) -> void:
	id = p_id
	display_name = p_display_name
	texture = p_texture
