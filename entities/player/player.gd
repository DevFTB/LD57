extends GroundedCharacterController
class_name Player

signal interacted

signal throw_initiated()
signal throw_released(data: ThrowReleasedEventData)

enum MovementState {
	FREE, GRAPPLE
}

@export var available_bomb_types: Array[BombType]

@export var throw_cooldown := 0.3
@export var throw_force_curve: Curve
@export var throw_strength_curve: Curve
@export var maximum_throw_hold_time := 1.0

var _holding_throw := false
var _throw_action_held_time := 0.0
var selected_bomb_item: Item
var can_throw := true

var upgrade_state: PlayerUpgradeState = PlayerUpgradeState.new()

var current_movement_state: MovementState = MovementState.FREE

@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent
@onready var bomb_cooldown: Timer = $BombCooldown

func _ready() -> void:
	var inv := bomb_inventory_component.inventory
	bomb_cooldown.wait_time = throw_cooldown
	if inv.size() > 0:
		var items := inv.get_items()
		selected_bomb_item = items.front()
		
	grapple_point.attached.connect(_on_grapple_attached)
		

func _physics_process(delta: float) -> void:
	check_collsions()
	
	match current_movement_state:
		MovementState.FREE:
			handle_jump()
			handle_direction(delta)
			handle_gravity(delta)
		MovementState.GRAPPLE:
			handle_grapple(delta)
	
	apply_movement()
	
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
		
		if Input.is_action_just_released("throw"):
			var strength := throw_strength_curve.sample_baked(_throw_action_held_time)
			_on_throw_release(strength)

		if _throw_action_held_time > maximum_throw_hold_time:
			_on_throw_release(1.0)
	
	if Input.is_action_just_released("traverse"):
		match grapple_point.grapple_state:
			GrapplePoint.GrappleState.INACTIVE:
				grapple_point.throw(global_position.direction_to(get_global_mouse_position()))
			_:
				grapple_point.cancel()
				current_movement_state = MovementState.FREE

@export var grapple_speed: float = 400.0
@onready var grapple_point: GrapplePoint = $GrapplePoint

const GRAPPLE_MIN_PULL_DISTANCE := 60

func handle_grapple(_delta: float) -> void:
	# pull player towards grapple point
	var direction := position.direction_to(grapple_point.position)
	var distance := position.distance_to(grapple_point.position)
	
	if distance > GRAPPLE_MIN_PULL_DISTANCE:
		_frame_velocity = direction * grapple_speed

func _on_grapple_attached() -> void:
	current_movement_state = MovementState.GRAPPLE


func switch_selected_bomb(index: int) -> void:
	var items := bomb_inventory_component.inventory.get_items()
	
	if items.size() > index:
		selected_bomb_item = items[index]
		
const UPGRADE_BOMB_HARDNESS = preload("res://systems/upgrades/upgrade_bomb_hardness.tres")
const UPGRADE_BOMB_RADIUS = preload("res://systems/upgrades/upgrade_bomb_radius.tres")
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
	var bomb_type: BombType = (selected_bomb_item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT)).duplicate()
	
	# apply upgrades
	bomb_type.hardness += upgrade_state.get_value(UPGRADE_BOMB_HARDNESS)
	bomb_type.explosion_radius += upgrade_state.get_value(UPGRADE_BOMB_RADIUS)

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

class ThrowReleasedEventData:
	var position: Vector2
	var impulse: Vector2
	var bomb_type: BombType
