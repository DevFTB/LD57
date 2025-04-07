extends Node2D
class_name Jetpack

signal fuel_changed

enum JetpackState {
	OFF, ON
}
## The current amount of fuel in the jetpack.

@export var base_fuel: float = 100.0

## How fast the jetpack burns fuel.
@export var fuel_burn_rate: float = 1.0

## The force applied by the jetpack.
@export var acceleration := 2000.0

## Maximum speed whilst being pushed by the jetpack.
@export var maximum_speed := 1000.0

var state: JetpackState = JetpackState.OFF

var fuel_multiplier = 1

@onready var player: Player = get_parent()

@onready var particles: GPUParticles2D = $GPUParticles2D

@onready var fuel: float = 100.0:
	set(value):
		fuel = value
		fuel_changed.emit(fuel)

func _ready() -> void:
	particles.emitting = false
	player.movement_state_changed.connect(_on_movement_state_changed)

		
func restock() -> void:
	fuel = get_max_fuel()

func handle_action(key: StringName) -> void:
	# Take control when jump action is pressed.
	if Input.is_action_just_pressed(key):
		activiate()
		player.set_movement_state(Player.MovementState.JETPACK)
		
	elif Input.is_action_just_released(key):
		cancel()
		player.free_movement(Player.MovementState.JETPACK)
		
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

func activiate() -> void:
	state = JetpackState.ON
	particles.emitting = true
	$JetpackStart.play()
	$JetpackLoop.play()

func get_max_fuel():
	return base_fuel * fuel_multiplier

func cancel() -> void:
	state = JetpackState.OFF
	particles.emitting = false
	$JetpackLoop.stop()

func _on_movement_state_changed(new_state: Player.MovementState) -> void:
	# If the movement state is set to different state while this state is active, gracefully cancel.
	if new_state != Player.MovementState.JETPACK and state == JetpackState.ON:
		cancel()
