extends Resource
class_name Upgrade

@export var id: StringName
@export var display_name: String
@export var texture: Texture2D
@export var num_tiers: int:
	get:
		return num_tiers
var levels: Array[int]


func _init(p_id: StringName = "default", p_display_name: String = "Item", p_texture: Texture2D = null) -> void:
	id = p_id
	display_name = p_display_name
	texture = p_texture


func add_level(tier):
	if levels.size() < num_tiers:
		levels.resize(num_tiers)
		levels.fill(0)
	levels[tier] += 1
