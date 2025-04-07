@tool
extends Resource
class_name Upgrade

@export var upgrade_type : PlayerUpgradeState.UpgradeType
@export var mult = true
@export var tier_value_in_tooltip = true
@export var tooltip_string: String
@export var display_name: String
@export var texture: Texture2D
@export var num_tiers: int:
	get:
		return num_tiers

@export var tier_costs: Array[int]
@export var tier_values: Array
@export var current_level_str = "[color=grey]%s[/color]" 
@export var value_str = "[color=green](+%s)[/color] " 

var levels: Array[int]

func _init(p_texture: Texture2D = null) -> void:
	texture = p_texture

func add_level(tier):
	if levels.size() < num_tiers:
		levels.resize(num_tiers)
		levels.fill(0)
	levels[tier] += 1

func get_text(tier, current_level):
	if tier_value_in_tooltip:
		var val = tier_values[tier]
		if mult: val = (val - 1) * 100
		var current_val = val * current_level
		val = str(snapped(val, 0.01))
		current_val = str(snapped(current_val, 0.01))
		if mult:
			val += "%"
			current_val += "%"
		return current_level_str % [current_val] + value_str % [val] + tooltip_string
	else: return tooltip_string
