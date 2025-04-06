extends EnemyState

var _grounded
@export var jump_power: float = 250

## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	if enemy.is_on_floor() and not _grounded:
		_grounded = true
	
	if not enemy.is_on_floor() and _grounded:
		_grounded = false
		
	enemy.move_and_slide()
	
	var target_pos: Vector2 = enemy.nav.get_next_path_position() - enemy.global_position
	var target_direction = target_pos.normalized()
	
	# move only if grounded
	if _grounded:
		# jump if next nav location is higher and not on ceiling
		if not enemy.is_on_ceiling() and target_direction.y < 0:
			enemy.velocity.y = -jump_power
			
		# else just move towards next nav location horizontally
		enemy.velocity.x = enemy.enemy_stats.move_speed * (1 if target_direction.x > 0 else -1)
	
	if enemy.is_on_ceiling():
		enemy.velocity.y = maxf(0, enemy.velocity.y)
		
	handle_gravity(_delta)
	
	#enemy.velocity = target_direction * enemy.enemy_stats.move_speed * _delta * 10
	
	#if enemy.global_position.distance_to(enemy.nav.get_final_position()) > 100:
		#finished.emit(IDLE)
		
func handle_gravity(_delta: float) -> void:
	if enemy.enemy_stats.is_grounded == true and not _grounded:
		print("handle_gravity", enemy.velocity)
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
