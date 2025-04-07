extends Node2D
class_name RopeClimb

signal fuel_changed

enum ClimbingState {
	OFF, ON
}


## The speed of climbing.
@export var climb_speed := 300.0

var state: ClimbingState = ClimbingState.OFF

@onready var player: Player = get_parent()


func _ready() -> void:
	player.movement_state_changed.connect(_on_movement_state_changed)


func handle_action(key: StringName) -> void:
	# Take control when jump action is pressed.
	if Input.is_action_just_pressed(key):
		activiate()
		player.set_movement_state(Player.MovementState.CLIMBING)
		
	elif Input.is_action_just_released(key):
		cancel()
		player.free_movement(Player.MovementState.CLIMBING)
		

## Calculates the velocity for the player when it's using this traversal method.
func calculate_frame_velocity(delta: float) -> Vector2:
	if state == ClimbingState.ON:
		var new_frame_velocity = Vector2(0,-climb_speed)
		return new_frame_velocity
	else:
		return Vector2()


func activiate() -> void:
	state = ClimbingState.ON


func cancel() -> void:
	state = ClimbingState.OFF


func _on_movement_state_changed(new_state: Player.MovementState) -> void:
	# If the movement state is set to different state while this state is active, gracefully cancel.
	if new_state != Player.MovementState.CLIMBING and state == ClimbingState.ON:
		cancel()
