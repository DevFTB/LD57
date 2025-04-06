@tool
extends Resource
class_name Upgrade

enum UpgradeType {
	BOMB_RADIUS, BOMB_HARDNESS
}

@export var tier_value_in_tooltip = true
@export var tooltip_string: String
@export var type: UpgradeType
@export var display_name: String
@export var texture: Texture2D
@export var num_tiers: int:
	get:
		return num_tiers

@export var tier_costs: Array[int]
@export var tier_values: Array

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

func get_text(tier):
	if tier_value_in_tooltip:	return tooltip_string % [tier_values[tier]]
	else: return tooltip_string
