extends GroundedCharacterController
class_name Player

signal interacted

signal throw_initiated()
signal throw_released(data: ThrowReleasedEventData)
signal depth_changed(depth)

enum MovementState {
	FREE, GRAPPLE, JETPACK
}

enum TraversalMethod {
	NONE, GRAPPLE, JETPACK
}

@export var available_bomb_types: Array[BombType]

@export var throw_cooldown := 0.3
@export var throw_force_curve: Curve
@export var throw_strength_curve: Curve
@export var maximum_throw_hold_time := 1.0

@export var traversal_method: TraversalMethod = TraversalMethod.NONE

var _holding_throw := false
var _throw_action_held_time := 0.0
var selected_bomb_item: Item
var can_throw := true
var current_depth := 0

var upgrade_state: PlayerUpgradeState = PlayerUpgradeState.new()

var current_movement_state: MovementState = MovementState.FREE

@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var bomb_cooldown: Timer = $BombCooldown
@onready var grapple_point: GrapplePoint = $GrapplePoint
@onready var jetpack: Jetpack = $Jetpack
@onready var spawn_location: Vector2 = global_position
@onready var animation = $AnimationPlayer

func _ready() -> void:
	var inv := bomb_inventory_component.inventory
	bomb_cooldown.wait_time = throw_cooldown
	if inv.size() > 0:
		var items := inv.get_items()
		selected_bomb_item = items.front()
		
	grapple_point.attached.connect(_on_grapple_attached)

	#connect signals
	if health_component:
		health_component.died.connect(_on_death)
	
func _physics_process(delta: float) -> void:
	check_collsions()
	
	match traversal_method:
		TraversalMethod.GRAPPLE:
			grapple_point.handle_action(&"traverse")
		TraversalMethod.JETPACK:
			jetpack.handle_action(&"traverse")
	
	match current_movement_state:
		MovementState.FREE:
			handle_jump()
			handle_direction(delta)
			handle_gravity(delta)
		MovementState.GRAPPLE:
			handle_grapple(delta)
		MovementState.JETPACK:
			handle_direction(delta)
			handle_gravity(delta)
			handle_jetpack(delta)
	
	apply_movement()
	
	current_depth = calculate_depth(global_position.y)
	if not health_component.is_dead:
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

func handle_grapple(delta: float) -> void:
	_frame_velocity = grapple_point.calculate_frame_velocity(delta)

func _on_grapple_attached() -> void:
	current_movement_state = MovementState.GRAPPLE

func handle_jetpack(delta: float) -> void:
	_frame_velocity = jetpack.calculate_frame_velocity(delta)
	
func _process(delta):
	if not health_component.is_dead:
		super._process(delta)
func switch_selected_bomb(index: int) -> void:
	var items := bomb_inventory_component.inventory.get_items()
	
	if items.size() > index:
		selected_bomb_item = items[index]
		
const UPGRADE_BOMB_HARDNESS = preload("res://systems/upgrades/upgrade_bomb_hardness.tres")
const UPGRADE_BOMB_RADIUS = preload("res://systems/upgrades/upgrade_bomb_radius.tres")
func initiate_throw() -> void:
	_holding_throw = true
	throw_initiated.emit()
	# Start bomb throw cooldown
	bomb_cooldown.start()
	can_throw = false

func _on_throw_release(strength = 1.0) -> void:
	# Reset throw strength timer
	_holding_throw = false
	_throw_action_held_time = 0.0
	
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

#calculates depth based on spawn position
func calculate_depth(current_y):
	var depth = (current_y - spawn_location.y) / 32 * 0.5
	if depth != current_depth:
		depth_changed.emit(depth)
	return depth

func _on_bomb_cooldown_timeout():
	can_throw = true

class ThrowReleasedEventData:
	var position: Vector2
	var impulse: Vector2
	var bomb_type: BombType

func _on_death():
	health_component.is_invulnerable = true
	#drop all resources
	animation.play("death") # plays death animation and resets the player when it is done.

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		health_component.reset()
		animation.play("RESET")
		velocity = Vector2.ZERO
		global_position = spawn_location
