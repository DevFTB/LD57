extends Resource
class_name Item
@export var id: StringName
@export var display_name: String
@export var texture: Texture2D

@export var data_components: Dictionary[DataCompontents, Variant]

enum DataCompontents {
	BOMB_DATA_COMPONENT
}

func _init(p_id: StringName = "default", p_display_name: String = "Item", p_texture: Texture2D = null) -> void:
	id = p_id
	display_name = p_display_name
	texture = p_texture

func set_data_component(key: DataCompontents, value: Variant) -> void:
	data_components.set(key, value)
	
func get_data_component(key: DataCompontents) -> Variant:
	return data_components.get(key)
