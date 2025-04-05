extends CharacterBody2D
class_name GroundedCharacterController

signal grounded_changed(grounded: bool)
signal jumped

@export_group("Movement")
## The top horizontal movement speed
@export var max_speed := 14

## The player's capacity to gain horizontal speed
@export var acceleration := 120

## The pace at which the player comes to a stop
@export var ground_deceleration := 60

## Deceleration in air only after stopping input mid-air"
@export var air_deceleration := 30

## A constant downward force applied while grounded. Helps on slopes
@export var grounding_force := 1.5

@export_group("Jump")
## The immediate velocity applied when jumping
@export var jump_power := 36

## The maximum vertical movement speed
@export var max_fall_speed := 40

## The player's capacity to gain fall speed. a.k.a. In Air Gravity
@export var fall_acceleration := 110

## The gravity multiplier added when jump is released early
@export var jump_end_early_gravity_modifier := 3

## The time before coyote jump becomes unusable. Coyote jump allows jump to execute even after leaving a ledge
@export var coyote_time := .15

## The amount of time we buffer a jump. This allows jump input before actually hitting the ground
@export var jump_buffer := .2

var has_buffered_jump: bool:
	get:
		return _buffered_jump_usable and _time < _time_jump_was_pressed + jump_buffer
		
var can_use_coyote: bool:
	get:
		return _coyote_usable and not _grounded and _time < _frame_left_grounded + coyote_time

var _time := 0.0
var _frame_input: FrameInput = FrameInput.new()
var _frame_velocity := Vector2()
var last_inputted_direction := Vector2()

var _coyote_usable := false
var _buffered_jump_usable := false
var _ended_jump_early := false
var _grounded := false

var _jump_queued := false
var _time_jump_was_pressed := 0.0

var _frame_left_grounded := 0.0

func _process(delta: float) -> void:
	_time += delta
	
	gather_input()
	
func _physics_process(delta: float) -> void:
	check_collsions()
	
	handle_jump()
	handle_direction(delta)
	handle_gravity(delta)
	
	apply_movement()
	
func check_collsions() -> void:
	if is_on_ceiling():
		_frame_velocity.y = maxf(0, _frame_velocity.y)
	
	if is_on_floor() and not _grounded:
		_grounded = true
		_coyote_usable = true
		_buffered_jump_usable = true
		_ended_jump_early = false
		
		grounded_changed.emit(true)
	
	if not is_on_floor() and _grounded:
		_grounded = false
		_frame_left_grounded = _time
		
		grounded_changed.emit(false)

func handle_jump() -> void:
	if not _ended_jump_early and not _grounded and not _frame_input.jump_held and velocity.y < 0:
		_ended_jump_early = true
	
	if not _jump_queued and not has_buffered_jump:
		return
		
	if _grounded or can_use_coyote:
		execute_jump()
	
	_jump_queued = false

func execute_jump() -> void:
	_ended_jump_early = false
	_time_jump_was_pressed = 0.0
	_buffered_jump_usable = false
	_coyote_usable = false
	_frame_velocity.y = - jump_power
	
	jumped.emit()
	
func handle_direction(delta: float) -> void:
	if is_zero_approx(_frame_input.move.x):
		var deceleration := ground_deceleration if _grounded else air_deceleration
		_frame_velocity.x = move_toward(_frame_velocity.x, 0, deceleration * delta)
	else:
		last_inputted_direction = Vector2(signf(_frame_velocity.x), 0)
		_frame_velocity.x = move_toward(_frame_velocity.x, _frame_input.move.x * max_speed, acceleration * delta)

func handle_gravity(delta: float) -> void:
	if _grounded and _frame_velocity.y >= 0.0:
		_frame_velocity.y = grounding_force
	else:
		var in_air_gravity := fall_acceleration
		if _ended_jump_early and _frame_velocity.y < 0:
			in_air_gravity *= jump_end_early_gravity_modifier
		
		_frame_velocity.y = move_toward(_frame_velocity.y, max_fall_speed, in_air_gravity * delta)
	
func apply_movement() -> void:
	velocity = _frame_velocity
	move_and_slide()

func gather_input() -> void:
	_frame_input = FrameInput.new()
	_frame_input.jump_down = Input.is_action_just_pressed("jump")
	_frame_input.jump_held = Input.is_action_pressed("jump")
	_frame_input.move = Input.get_vector("move_left", "move_right", "move_down", "move_up")
	
	if _frame_input.jump_down:
		_jump_queued = true
		_time_jump_was_pressed = _time

class FrameInput:
	var jump_down: bool
	var jump_held: bool
	var move: Vector2
