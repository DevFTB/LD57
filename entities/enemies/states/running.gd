extends EnemyState

var _grounded
@export var jump_power: float = 250
#@export var jump_power: float = 300

@onready var _jump_dir = 0

## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	#var acceleration = enemy.enemy_stats.move_speed * 15
	
	if enemy.is_on_floor() and not _grounded:
		_grounded = true
		_jump_dir = 0
	
	if not enemy.is_on_floor() and _grounded:
		_grounded = false
		
	enemy.move_and_slide()
	
	var target_pos: Vector2 = enemy.nav.get_next_path_position() - enemy.global_position
	var target_direction = target_pos.normalized()
	
	# move only if grounded
	if _grounded:
		# jump if next nav location is higher and not on ceiling
		var min_jump_angle = PI/8
		if not enemy.is_on_ceiling() and target_direction.y < 0 and ((target_direction.angle() > (-PI + min_jump_angle)) and (target_direction.angle() < -min_jump_angle)):
			enemy.velocity.y = -jump_power
			#enemy.velocity.y = -jump_power * sin(Vector2.UP.dot(target_direction.normalized()) * PI/2)
			
		# else just move towards next nav location horizontally
		#if abs(enemy.velocity.x) < enemy.enemy_stats.move_speed:
			#enemy.velocity.x += acceleration * _delta * (1 if target_direction.x > 0 else -1)
			
		_jump_dir = signf(target_direction.x)
		enemy.velocity.x = enemy.enemy_stats.move_speed * _jump_dir
	else:
		# continue to apply jump x velocity when in air
		# remove if sus
		enemy.velocity.x = enemy.enemy_stats.move_speed * _jump_dir
	
	if enemy.is_on_ceiling():
		enemy.velocity.y = maxf(0, enemy.velocity.y)
		
	handle_gravity(_delta)
	
	#enemy.velocity = target_direction * enemy.enemy_stats.move_speed * _delta * 10
	
	if enemy.global_position.distance_to(enemy.nav.get_final_position()) > 1000:
		finished.emit(IDLE)
	
	if enemy.is_ranged and enemy.sees_player and enemy.global_position.distance_to(enemy.nav.get_final_position()) < enemy.enemy_stats.range:
		finished.emit(RANGED_ATTACKING)
		
		
func handle_gravity(_delta: float) -> void:
	if enemy.enemy_stats.is_grounded == true and not _grounded:
		enemy.velocity.y += enemy.gravity.y * _delta
	
## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_previous_state_path: String, _data := {}) -> void:
	pass
	#check_collsions()
	#enemy.velocity.x = 0.0
	##play idle anim
	#if enemy.enemy_stats.is_grounded == false:
		#enemy.velocity.y = 0.0
	#pass

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
