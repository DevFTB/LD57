extends GroundedCharacterController
class_name Player

class ThrowInitiatedEventData:
	var position: Vector2
	var impulse: Vector2
	var bomb_type: BombType
	
signal interacted
signal throw_initiated(data: ThrowInitiatedEventData)

@export var throw_force_curve: Curve
@export var available_bomb_types: Array[BombType]
@export var throw_cooldown := 0.3

var selected_bomb_item: Item
var can_throw := true

var upgrade_state: PlayerUpgradeState = PlayerUpgradeState.new()

@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent
@onready var bomb_cooldown: Timer = $BombCooldown

func _ready() -> void:
	var inv := bomb_inventory_component.inventory
	bomb_cooldown.wait_time = throw_cooldown
	if inv.size() > 0:
		var items := inv.get_items()
		selected_bomb_item = items.front()
		

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if Input.is_action_just_pressed("interact"):
		interacted.emit()
	
	if Input.is_action_just_pressed("throw"):
		if can_throw == true:
			initiate_throw()
		
	if Input.is_action_just_pressed("select_bomb_1"):
		switch_selected_bomb(0)
	if Input.is_action_just_pressed("select_bomb_2"):
		switch_selected_bomb(1)
	if Input.is_action_just_pressed("select_bomb_3"):
		switch_selected_bomb(2)

func switch_selected_bomb(index: int) -> void:
	var items := bomb_inventory_component.inventory.get_items()
	
	if items.size() > index:
		selected_bomb_item = items[index]
		
const UPGRADE_BOMB_HARDNESS = preload("res://systems/upgrades/upgrade_bomb_hardness.tres")
const UPGRADE_BOMB_RADIUS = preload("res://systems/upgrades/upgrade_bomb_radius.tres")
func initiate_throw() -> void:
	#cooldown
	can_throw = false
	bomb_cooldown.start()
	
	var direction := global_position.direction_to(get_global_mouse_position())
	
	var bomb_type : BombType = (selected_bomb_item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT)).duplicate()
	
	# apply upgrades
	bomb_type.hardness += upgrade_state.get_value(UPGRADE_BOMB_HARDNESS)
	bomb_type.explosion_radius += upgrade_state.get_value(UPGRADE_BOMB_RADIUS)


	var data := ThrowInitiatedEventData.new()
	data.position = global_position
	data.impulse = direction.normalized() * throw_force_curve.sample_baked(1.0)
	data.bomb_type = bomb_type
	
	if bomb_type.is_perishable:
		if bomb_inventory_component.inventory.has_item(selected_bomb_item):
			throw_initiated.emit(data)
			bomb_inventory_component.inventory.remove_item(selected_bomb_item, 1)
	else:
		throw_initiated.emit(data)


func _on_bomb_cooldown_timeout():
	can_throw = true
	pass # Replace with function body.
