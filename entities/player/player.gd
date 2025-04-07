extends GroundedCharacterController
class_name Player

signal interacted

signal throw_initiated()
signal throw_released(data: World.ThrowReleasedEventData)
signal depth_changed(depth)
signal selected_bomb_changed(bomb: Item)

signal traversal_method_unlocked(method: TraversalMethod)
signal movement_state_changed(new_movement_state: MovementState)
signal died

enum MovementState {
	FREE, GRAPPLE, JETPACK, BLOCKED, CLIMBING
}

enum TraversalMethod {
	NONE, GRAPPLE, JETPACK
}

@export var available_bomb_types: Array[BombType]

@export var throw_cooldown := 0.3
@export var throw_force_curve: Curve
@export var throw_strength_curve: Curve
@export var maximum_throw_hold_time := 1.0
@export var blast_resistance_factor := 0.5
@export var unlocked_traversal_methods: Array[TraversalMethod] = []



var _holding_throw := false
var _throw_action_held_time := 0.0
var selected_bomb_item: Item
var can_throw := true
var can_pickup := true
var can_climb := false
var current_depth := 0


var upgrade_state: PlayerUpgradeState = PlayerUpgradeState.new()

var current_movement_state: MovementState = MovementState.FREE

@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var bomb_cooldown: Timer = $BombCooldown
@onready var grapple_point: GrapplePoint = $GrapplePoint
@onready var jetpack: Jetpack = $Jetpack
@onready var rope_climb: RopeClimb = $RopeClimb
@onready var spawn_location: Vector2 = global_position
@onready var winch = $"../Winch"
@onready var holding_bomb = $Sprite2D/BombSprites

func _ready() -> void:
	throw_released.connect(StatsManager.add_to_stat.bind(StatsManager.Stat.BOMBS_THROWN, 1).unbind(1))
	if winch:
		winch.rope_area.body_entered.connect(_on_rope_entered)
		winch.rope_area.body_exited.connect(_on_rope_exited)
	
	var inv := bomb_inventory_component.inventory
	bomb_cooldown.wait_time = throw_cooldown
	if inv.size() > 0:
		var items := inv.get_items()
		selected_bomb_item = items.front()
		selected_bomb_changed.emit(selected_bomb_item)
		
	#connect signals
	if health_component:
		health_component.died.connect(_on_death)
		
func unlock_traversal_method(method: TraversalMethod) -> void:
	if not unlocked_traversal_methods.has(method):
		unlocked_traversal_methods.append(method)
		traversal_method_unlocked.emit(method)
	pass
		
func set_movement_state(new_movement_state: MovementState) -> void:
	current_movement_state = new_movement_state
	movement_state_changed.emit(new_movement_state)

func free_movement(source: MovementState) -> void:
	# Only free the movement if the current movement state matches the source of the request.
	# Otherwise other states could override the control of the current state.
	if current_movement_state == source:
		current_movement_state = MovementState.FREE
		movement_state_changed.emit(current_movement_state)
	
func _physics_process(delta: float) -> void:
	check_collisions()
	
	if not current_movement_state == MovementState.BLOCKED:
		if can_climb:
			rope_climb.handle_action(&"climb")
		else:
			if current_movement_state == MovementState.CLIMBING:
				current_movement_state = MovementState.FREE
		for method in unlocked_traversal_methods:
			if method == TraversalMethod.GRAPPLE: # and (current_movement_state == MovementState.FREE or current_movement_state == MovementState.GRAPPLE):
				grapple_point.handle_action(&"traverse")
			if method == TraversalMethod.JETPACK: # and (current_movement_state == MovementState.FREE or current_movement_state == MovementState.JETPACK):
				match jetpack.state:
					jetpack.JetpackState.OFF:
						if not is_on_floor():
							jetpack.handle_action(&"jump")
					jetpack.JetpackState.ON:
						jetpack.handle_action(&"jump")
		
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
		MovementState.BLOCKED:
			pass
		MovementState.CLIMBING:
			handle_climbing(delta)
	
	apply_movement()
	
	current_depth = calculate_depth(global_position.y)
	if not health_component.is_dead:
		if Input.is_action_just_pressed("interact"):
			interacted.emit()
			
		handle_bomb_switch(range(9))

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
	
func handle_bomb_switch(indexes: Array) -> void:
	for i in indexes:
		var action := "select_bomb_%d" % (i + 1)
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			switch_selected_bomb(i)

func handle_grapple(delta: float) -> void:
	_frame_velocity = grapple_point.calculate_frame_velocity(delta)

func handle_jetpack(delta: float) -> void:
	_frame_velocity = jetpack.calculate_frame_velocity(delta)

func handle_climbing(delta: float) -> void:
	_frame_velocity = rope_climb.calculate_frame_velocity(delta)

func _process(delta):
	if not health_component.is_dead:
		super._process(delta)
func switch_selected_bomb(index: int) -> void:
	var items := bomb_inventory_component.inventory.get_items()
	
	if items.size() > index:
		selected_bomb_item = items[index]
		selected_bomb_changed.emit(selected_bomb_item)
		
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
	$ThrowSound.pitch_scale = randf_range(0.9, 1.1)
	$ThrowSound.play()
	# Throw towards mouse.
	var direction := global_position.direction_to(get_global_mouse_position())
	
	# Get bomb type from selected item.
	var bomb_type: BombType = (selected_bomb_item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT)).duplicate()
	
	# apply upgrades
	bomb_type.hardness += upgrade_state.get_value(UPGRADE_BOMB_HARDNESS)
	bomb_type.explosion_radius += upgrade_state.get_value(UPGRADE_BOMB_RADIUS)

	var data := World.ThrowReleasedEventData.new()
	data.position = global_position
	data.impulse = direction.normalized() * throw_force_curve.sample_baked(strength)
	data.bomb_type = bomb_type
	
	# Consume item from inventory if perishable
	if bomb_type.is_perishable:
		if bomb_inventory_component.inventory.has_item(selected_bomb_item):
			throw_released.emit(data)
			bomb_inventory_component.inventory.remove_item(selected_bomb_item, 1)
			if bomb_inventory_component.inventory.get_item_amount(selected_bomb_item) == 0:
				switch_selected_bomb(0)
	else:
		throw_released.emit(data)

#calculates depth based on spawn position
func calculate_depth(current_y):
	var depth = (current_y - spawn_location.y) / 32 * 0.5
	if depth != current_depth:
		StatsManager.surpass_stat(StatsManager.Stat.MAX_DEPTH, current_depth)
		depth_changed.emit(depth)
	return depth

func _on_bomb_cooldown_timeout():
	can_throw = true

func _on_death():
	StatsManager.add_to_stat(StatsManager.Stat.DEATH_COUNT, 1)
	
	set_movement_state(MovementState.BLOCKED)
	health_component.is_invulnerable = true
	can_throw = false
	can_pickup = false
	if _holding_throw:
		_on_throw_release(0)
	var inventory: Inventory = mineral_inventory_component.inventory

	var world: World = get_tree().get_first_node_in_group("world")
	for item in inventory.get_items():
		world.call_deferred("drop_item_entity", global_position, item, inventory.get_item_amount(item))
		inventory.remove_item(item, inventory.get_item_amount(item))

	$DeathSound.play()
	died.emit()

func reset_player() -> void:
	can_throw = true
	can_pickup = true
	health_component.reset()
	velocity = Vector2.ZERO
	global_position = spawn_location
	set_movement_state(MovementState.FREE)
	

func _play_hurt_sounds() -> void:
	$HurtSound.pitch_scale = randf_range(0.9, 1.1)
	$HurtSound.play()
	
func _on_rope_entered(body):
	if body is Player:
		can_climb = true

	
func _on_rope_exited(body):
	if body is Player:
		can_climb = false


func _on_selected_bomb_changed(bomb):
	for child in holding_bomb.get_children():
		child.texture = bomb.texture
	pass # Replace with function body.
