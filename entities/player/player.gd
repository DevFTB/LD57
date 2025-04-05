extends GroundedCharacterController
class_name Player

class ThrowReleasedEventData:
	var position: Vector2
	var impulse: Vector2
	var bomb_type: BombType
	
signal interacted

signal throw_initiated()
signal throw_released(data: ThrowReleasedEventData)

@export var available_bomb_types: Array[BombType]

@export var throw_cooldown := 0.3
@export var throw_force_curve: Curve
@export var throw_strength_curve: Curve
@export var maximum_throw_hold_time := 1.0

var _holding_throw := false
var _throw_action_held_time := 0.0
var selected_bomb_item: Item
var can_throw := true


@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent
@onready var health_component : HealthComponent = $HealthComponent
@onready var bomb_cooldown: Timer = $BombCooldown
@onready var spawn_location : Vector2 = global_position

func _ready() -> void:
	var inv := bomb_inventory_component.inventory
	bomb_cooldown.wait_time = throw_cooldown
	if inv.size() > 0:
		var items := inv.get_items()
		selected_bomb_item = items.front()
	
	#connect signals
	if health_component:
		health_component.died.connect(_on_death)
	
	#set spawn location
	

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Input.is_action_just_pressed("interact"):
		interacted.emit()
	
		
	if Input.is_action_just_pressed("select_bomb_1"):
		switch_selected_bomb(0)
	if Input.is_action_just_pressed("select_bomb_2"):
		switch_selected_bomb(1)
	if Input.is_action_just_pressed("select_bomb_3"):
		switch_selected_bomb(2)
		
	if Input.is_action_just_pressed("throw"):
		if can_throw == true:
			initiate_throw()

	if _holding_throw:
		_throw_action_held_time += delta
		print(_throw_action_held_time)
		
		if Input.is_action_just_released("throw"):
			var strength := throw_strength_curve.sample_baked(_throw_action_held_time)
			_on_throw_release(strength)

		if _throw_action_held_time > maximum_throw_hold_time:
			_on_throw_release(1.0)

func switch_selected_bomb(index: int) -> void:
	var items := bomb_inventory_component.inventory.get_items()
	
	if items.size() > index:
		selected_bomb_item = items[index]

func initiate_throw() -> void:
	_holding_throw = true
	throw_initiated.emit()

func _on_throw_release(strength = 1.0) -> void:
	# Reset throw strength timer
	_holding_throw = false
	_throw_action_held_time = 0.0

	# Start bomb throw cooldown
	bomb_cooldown.start()
	can_throw = false
	
	# Throw towards mouse.
	var direction := global_position.direction_to(get_global_mouse_position())
	
	# Get bomb type from selected item.
	var bomb_type := selected_bomb_item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT) as BombType

	var data := ThrowReleasedEventData.new()
	data.position = global_position
	data.impulse = direction.normalized() * throw_force_curve.sample_baked(strength)
	data.bomb_type = bomb_type
	
	# Consume item from inventory if perishable
	if bomb_type.is_perishable:
		if bomb_inventory_component.inventory.has_item(selected_bomb_item):
			throw_released.emit(data)
			bomb_inventory_component.inventory.remove_item(selected_bomb_item, 1)
	else:
		throw_released.emit(data)

func _on_bomb_cooldown_timeout():
	can_throw = true

func _on_death():
	health_component.is_invulnerable = true
	#drop all resources
	#play death animation
	health_component.reset()
	velocity = Vector2.ZERO
	global_position = spawn_location
	pass
