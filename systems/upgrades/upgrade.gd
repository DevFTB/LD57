extends Resource
class_name Upgrade

enum UpgradeType {
	BOMB_RADIUS, BOMB_HARDNESS
}

@export var type: UpgradeType
@export var display_name: String
@export var texture: Texture2D
@export var num_tiers: int:
	get:
		return num_tiers

@export var tier_value_map: Dictionary[int, Variant] = {}

var levels: Array[int]

func _init(p_type: UpgradeType = UpgradeType.BOMB_RADIUS, p_display_name: String = "Item", p_texture: Texture2D = null) -> void:
	type = p_type
	display_name = p_display_name
	texture = p_texture


func add_level(tier):
	if levels.size() < num_tiers:
		levels.resize(num_tiers)
		levels.fill(0)
	levels[tier] += 1
