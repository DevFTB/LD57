@tool
extends Control
class_name UpgradeButton

@export var upgrade: Upgrade
@export var dependecies: Dictionary[UpgradeButton, int]

@onready var player: Player = get_tree().get_first_node_in_group("player")

@onready var label = $Label
@onready var button: Button = $Button

var current_tier: int:
	get:
		return player.upgrade_state.get_tier(upgrade)


func _ready() -> void:
	button.pressed.connect(_on_pressed)
	player.upgrade_state.changed.connect(_on_upgrade_state_changed)
	_on_upgrade_state_changed()

const LEVEL_FORMAT_STRING := "%d/%d"
func _on_upgrade_state_changed() -> void:
	label.text = LEVEL_FORMAT_STRING % [current_tier, upgrade.num_tiers - 1]
	
	button.disabled = not can_upgrade()
	button.icon = upgrade.texture

const ITEM_UPGRADIUM = preload("res://systems/inventory/items/item_upgradium.tres")

func _on_pressed():
	if can_upgrade():
		player.mineral_inventory_component.inventory.remove_item(ITEM_UPGRADIUM, 1)
		player.upgrade_state.increment_upgrade_tier(upgrade)

func can_upgrade():
	# TODO: Check money is enough and take money
	var has_items := player.mineral_inventory_component.inventory.has_item(ITEM_UPGRADIUM, 1)
	var valid_level := current_tier == 0 or current_tier < upgrade.num_tiers
	
	if not (has_items and valid_level):
		return false
	else:
		var dependencies_satisfied := dependecies.size() == 0
		if not dependencies_satisfied:
			for dependency in dependecies:
					dependencies_satisfied = dependecies and dependency.current_level >= dependecies[dependency]
		
		return dependencies_satisfied

func _draw():
	for dependency in dependecies:
		draw_line(dependency.get_position() + Vector2(dependency.size.x / 2, 0) - self.get_position(), Vector2(self.get_size().x / 2, self.get_size().y), Color.BLACK, 3)
