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

var selected_bomb_item: Item

@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent

func _ready() -> void:
	var inv := bomb_inventory_component.inventory
	if inv.size() > 0:
		var items := inv.get_items()
		selected_bomb_item = items.front()
		
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if Input.is_action_just_pressed("interact"):
		interacted.emit()
	
	if Input.is_action_just_pressed("throw"):
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

func initiate_throw() -> void:
	var direction := global_position.direction_to(get_global_mouse_position())
	
	var bomb_type := selected_bomb_item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT) as BombType

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
