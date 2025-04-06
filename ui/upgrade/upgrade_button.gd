@tool
extends Control
class_name UpgradeButton

@export_tool_button("generate") var generate_button = generate
@export var upgrade : Upgrade
@export var dependecies: Dictionary[UpgradeButton, int]
@export var max_level = 3
@export var tier : int

@onready var player : Player = get_tree().get_first_node_in_group("player")
@onready var label = $Label
@onready var button: Button = $Button
@onready var maxed_rect: ColorRect = $Button/Maxed

var current_level: int:
	get:
		if not player: return 0
		else: return player.upgrade_state.get_tier_level(upgrade, tier)


func _ready() -> void:
	button.pressed.connect(_on_pressed)
	player.upgrade_state.changed.connect(_on_upgrade_state_changed)
	_on_upgrade_state_changed()

const LEVEL_FORMAT_STRING := "%d/%d"
func _on_upgrade_state_changed() -> void:
	label.text = LEVEL_FORMAT_STRING % [current_level, max_level]
	visible = dependencies_satisfied(1)
	button.disabled = not can_upgrade() and not maxed()
	maxed_rect.visible = maxed()
	button.icon = upgrade.texture

func generate() -> void:
	$Label.text = LEVEL_FORMAT_STRING % [0, max_level]
	$Button.icon = upgrade.texture
	queue_redraw()

const ITEM_UPGRADIUM = preload("res://systems/inventory/items/item_upgradium.tres")

func _on_pressed():
	if can_upgrade(): 
		player.mineral_inventory_component.inventory.remove_item(ITEM_UPGRADIUM, 1)
		player.upgrade_state.increment_upgrade_tier_level(upgrade, tier)
		
func maxed():
	return player.upgrade_state.get_tier_level(upgrade, tier) == max_level


func can_upgrade():
	# TODO: Check money is enough and take money
	var has_items := player.mineral_inventory_component.inventory.has_item(ITEM_UPGRADIUM, 1)
	return dependencies_satisfied() and not maxed() and has_items

func dependencies_satisfied(force_min=0) -> bool:

	var dependencies_satisfied := dependecies.size() == 0
	if not dependencies_satisfied:
		for dependency in dependecies:
			var min : int
			if force_min > 0: min = force_min
			else: min = dependecies[dependency]
			dependencies_satisfied = dependecies and dependency.current_level >= min 
	
	return dependencies_satisfied
	

func _draw():
	for dependency in dependecies:
		draw_line(dependency.get_position()+Vector2(dependency.size.x/2,0)-self.get_position(), Vector2(self.get_size().x/2, self.get_size().y), Color.BLACK, 3)
	

func display_tooltip():
	var tooltip =  preload("res://ui/upgrade/upgrade_tooltip.tscn").instantiate()
	tooltip.config(upgrade.get_text(tier), LEVEL_FORMAT_STRING % [current_level, max_level], "1")
	return tooltip

	
