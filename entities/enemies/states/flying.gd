extends EnemyState

## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	enemy.move_and_slide()
	var target_pos: Vector2 = enemy.nav.get_next_path_position() - enemy.global_position
	var target_direction = target_pos.normalized()
	enemy.last_moved_direction = target_direction.normalized()
	enemy.velocity = target_direction * enemy.enemy_stats.move_speed * _delta * 10
	
	if enemy.is_ranged and enemy.global_position.distance_to(enemy.nav.get_final_position()) < enemy.enemy_stats.range:
		finished.emit(RANGED_ATTACKING)
	elif enemy.global_position.distance_to(enemy.nav.get_final_position()) <= 20:
		finished.emit(IDLE)

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_previous_state_path: String, _data := {}) -> void:
	enemy.velocity.x = 0.0
	#play idle anim
	if enemy.enemy_stats.is_grounded == false:
		enemy.velocity.y = 0.0
	pass

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
