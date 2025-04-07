extends EnemyState

@export var knockback_velocity_multiplier: float = 400
@export var knockback_time: float = 0.4

## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	enemy.move_and_slide()
	
	if enemy.is_on_ceiling():
		enemy.velocity.y = maxf(0, enemy.velocity.y)
	
	handle_gravity(_delta)
	
	# TODO: improve
	#enemy.velocity *= 0.8

func handle_gravity(_delta: float) -> void:
	if enemy.enemy_stats.is_grounded == true and not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity.y * _delta

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_previous_state_path: String, _data := {}) -> void:
	$KnockbackTimer.start(knockback_time)
	
	var knockback_origin = _data["knockback_origin"]
	var knockback_amount = _data["knockback_amount"]
	enemy.velocity = (enemy.global_position - knockback_origin).normalized() * knockback_velocity_multiplier * knockback_amount
	var knockback_tween = get_tree().create_tween()
	if enemy.enemy_stats.is_grounded:
		enemy.velocity.y = max(0, enemy.velocity.y)
		knockback_tween.parallel().tween_property(enemy, "velocity:x", 0, knockback_time)
	else:
		knockback_tween.parallel().tween_property(enemy, "velocity", Vector2.ZERO, knockback_time)
	
## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	$KnockbackTimer.stop()


func _on_knockback_timer_timeout() -> void:
	finished.emit(IDLE)
