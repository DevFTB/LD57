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
	if enemy.enemy_stats.is_grounded == true:
		enemy.velocity.y += enemy.gravity.y + _delta
	
	pass

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(previous_state_path: String, data := {}) -> void:
	enemy.velocity.x = 0.0
	#play idle anim
	if enemy.enemy_stats.is_grounded == false:
		enemy.velocity.y = 0.0
	pass

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
