extends Node2D
class_name Jetpack

enum JetpackState {
	OFF, ON
}

## The current amount of fuel in the jetpack.
@export var fuel: float = 100.0

## How fast the jetpack burns fuel.
@export var fuel_burn_rate: float = 1.0

## The force applied by the jetpack.
@export var acceleration := 2000.0

## Maximum speed whilst being pushed by the jetpack.
@export var maximum_speed := 1000.0

var state: JetpackState = JetpackState.OFF

@onready var player: Player = get_parent()

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	particles.emitting = false

func handle_action(key: StringName) -> void:
	# Take control when traverse action is pressed.
	if Input.is_action_just_pressed(key):
		state = JetpackState.ON
		player.current_movement_state = Player.MovementState.JETPACK
		particles.emitting = true 
		$JetpackStart.play()
		$JetpackLoop.play()

	elif Input.is_action_just_released(key):
		state = JetpackState.OFF
		player.current_movement_state = Player.MovementState.FREE
		particles.emitting = false
		$JetpackLoop.stop()


func _physics_process(delta: float) -> void:
	# Burn fuel when on.
	if state == JetpackState.ON:
		fuel = move_toward(fuel, 0, fuel_burn_rate * delta)

## Calculates the velocity for the player when it's using this traversal method.
func calculate_frame_velocity(delta: float) -> Vector2:
	if state == JetpackState.ON and not is_zero_approx(fuel):
		var jetpack_thrust := Vector2.UP * acceleration * delta
		var new_frame_velocity = jetpack_thrust + player._frame_velocity
		new_frame_velocity = new_frame_velocity.limit_length(maximum_speed)
		return new_frame_velocity
	else:
		return Vector2()
	
func add_fuel(amount: float) -> void:
	fuel += amount
