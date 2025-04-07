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
@export var blast_resistance_factor := 1
@export var unlocked_traversal_methods: Array[TraversalMethod] = []
@export var base_magnet_range := 100
@export var invulnerability_cooldown := 30

@export var upgrade_state: PlayerUpgradeState = PlayerUpgradeState.new()

var magnet_strength_multiplier = 1
var bomb_damage_multiplier = 1
var bomb_radius_multiplier = 1
var jetpack_fuel_multiplier = 1
var invulnerability_duration: float = 0
var multi_bomb_chance_percent := 0.0
var multi_bomb_amount := 1


var _holding_throw := false
var _throw_action_held_time := 0.0
var selected_bomb_item: Item
var can_throw := true
var can_pickup := true
var can_climb := false
var current_depth := 0
var blast_resistance := 0

var world: Node
var frozen := false

var current_movement_state: MovementState = MovementState.FREE

@onready var mineral_inventory_component: InventoryComponent = $MineralInventoryComponent
@onready var bomb_inventory_component: InventoryComponent = $BombInventoryComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component = $HurtboxComponent
@onready var bomb_cooldown: Timer = $BombCooldown
@onready var grapple_point: GrapplePoint = $GrapplePoint
@onready var jetpack: Jetpack = $Jetpack
@onready var rope_climb: RopeClimb = $RopeClimb
@onready var spawn_location: Vector2 = global_position
@onready var winch = $"../Winch"
@onready var holding_bomb = $Sprite2D/BombSprites

func _ready() -> void:
	upgrade_state.upgraded.connect(on_upgrade)
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

	world = get_tree().get_first_node_in_group("world")
	
func on_upgrade(upgrade: Upgrade, tier):
	match upgrade.upgrade_type:
		PlayerUpgradeState.UpgradeType.JETPACK:
			unlocked_traversal_methods.append(TraversalMethod.JETPACK)
		PlayerUpgradeState.UpgradeType.BOMB_HARDNESS:
			bomb_damage_multiplier = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.BOMB_RADIUS:
			bomb_radius_multiplier = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.GRAPPLE_RANGE:
			grapple_point.grapple_range_multiplier = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.JETPACK_FUEL:
			jetpack.fuel_multiplier = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.MAGNET:
			magnet_strength_multiplier = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.HEALTH:
			health_component.set_maximum_health(health_component.base_maximum_health + upgrade_state.get_total_value(upgrade))
			health_component.reset()
		PlayerUpgradeState.UpgradeType.INVULNERABILITY:
			invulnerability_duration = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.MULTIBOMB:
			multi_bomb_chance_percent = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.MULTIBOMB_AMOUNT:
			multi_bomb_amount = upgrade_state.get_total_value(upgrade) + 1
		PlayerUpgradeState.UpgradeType.BLAST_RESISTANCE: # logarithmic scale
			hurtbox_component.blast_resistance_factor = upgrade_state.get_total_value(upgrade)
		PlayerUpgradeState.UpgradeType.STICKY_RESTOCK_AMOUNT:
			modify_restock_inventory(preload("res://systems/inventory/items/item_sticky_bomb.tres"), upgrade_state.get_total_value(upgrade))
		PlayerUpgradeState.UpgradeType.NUKE_RESTOCK_AMOUNT:
			modify_restock_inventory(preload("res://systems/inventory/items/item_nuclear_bomb.tres"), upgrade_state.get_total_value(upgrade))
		PlayerUpgradeState.UpgradeType.IMPACT_RESTOCK_AMOUNT:
			modify_restock_inventory(preload("res://systems/inventory/items/item_impact_bomb.tres"), upgrade_state.get_total_value(upgrade))
		PlayerUpgradeState.UpgradeType.SHRAPNEL_RESTOCK_AMOUNT:
			modify_restock_inventory(preload("res://systems/inventory/items/item_shrapnel_bomb.tres"), upgrade_state.get_total_value(upgrade))

func modify_restock_inventory(bomb_item: Item, amount: int):
	var inventory: Inventory = world.restock_inventory
	inventory.remove_item(bomb_item, inventory.get_item_amount(bomb_item))
	inventory.add_item(bomb_item, amount)
	world.restock_player(self)
	

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
	if not frozen:
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

func freeze() -> void:
	frozen = true

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
	bomb_type.hardness = bomb_type.hardness * bomb_damage_multiplier
	bomb_type.explosion_radius = bomb_type.explosion_radius * bomb_radius_multiplier
	var multi_bomb = false
	var thrown_bomb_amount := 1
	if randf_range(0, 100) <= multi_bomb_chance_percent:
		multi_bomb = true
		thrown_bomb_amount = 1 + multi_bomb_amount

	var data := World.ThrowReleasedEventData.new()
	data.position = global_position
	data.impulse = direction.normalized() * throw_force_curve.sample_baked(strength) * bomb_type.bomb_velocity_modifier
	data.bomb_type = bomb_type
	
	# Consume item from inventory if perishable
	if bomb_type.is_perishable:
		if bomb_inventory_component.inventory.has_item(selected_bomb_item):
			for i in range(0, thrown_bomb_amount):
				if multi_bomb:
					data.impulse.y *= randf_range(1 - (multi_bomb_amount * 0.1), 1 + (multi_bomb_amount * 0.1))
					data.position += Vector2(0, -15)
					data.random_fuse = true
				throw_released.emit(data)
			bomb_inventory_component.inventory.remove_item(selected_bomb_item, 1)
			if bomb_inventory_component.inventory.get_item_amount(selected_bomb_item) == 0:
				switch_selected_bomb(0)
	else:
		for i in range(0, thrown_bomb_amount):
			if multi_bomb:
				data.impulse.y *= randf_range(1 - (multi_bomb_amount * 0.1), 1 + (multi_bomb_amount * 0.1))
				data.position += Vector2(0, -15)
				data.random_fuse = true
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

func get_magnet_range():
	return base_magnet_range * magnet_strength_multiplier
