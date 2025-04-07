extends EnemyState
signal attacked()

@onready var ranged_attack_timer = $RangedAttackTimer
@export var ranged_attack: RangedAttack

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
		enemy.velocity.y += enemy.gravity.y * _delta
	
	# TODO: could be more efficnet spots to put it than here but should be nbd (use signal)
	try_attack()
	
	if (enemy.global_position.distance_to(enemy.nav.get_final_position()) > enemy.enemy_stats.range or
	 not enemy.sees_player):
		# TODO: should it really require sees_player? now it chases perhaps a bit too aggresively lol
		finished.emit(IDLE)

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_previous_state_path: String, _data := {}) -> void:
	enemy.velocity.x = 0.0
	#play idle anim
	if enemy.enemy_stats.is_grounded == false:
		enemy.velocity.y = 0.0
		
	try_attack()
	
		
func try_attack():
	if ranged_attack_timer.is_stopped():
		attacked.emit()
		ranged_attack.attack()
		ranged_attack_timer.start()

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
