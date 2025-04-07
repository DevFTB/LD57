extends CharacterBody2D
class_name GrapplePoint
signal attached()

enum GrappleState {
	INACTIVE, # Not thrown
	SEARCHING, # Flying through air to hit something
	ATTACHED # Hit something and is pulling the player.
}

## How fast the player moves while being pulled by the hook
@export var player_pull_speed: float = 1000.0

## The maximum distance at which a hook can attached to the tilemap
@export var max_attachment_distance := 1500.0

## How fast the grapple point flys through the world
@export var grapple_point_speed: float = 400.0

## The distance at which the grapple hook stops pulling to avoid janky collisions.
@export var grapple_min_pull_distance := 60

var grapple_state: GrappleState

var cooldown_active: bool:
	get:
		return not grapple_cooldown.is_stopped()

@onready var player: Player = get_parent()
@onready var grapple_cooldown: Timer = $GrappleCooldown

func _ready() -> void:
	set_state(GrappleState.INACTIVE)
	player.movement_state_changed.connect(_on_movement_state_changed)

func _physics_process(_delta: float) -> void:
	move_and_slide()
	queue_redraw()

	if grapple_state == GrappleState.SEARCHING:
		if position.distance_to(player.position) > max_attachment_distance:
			cancel()
		elif get_slide_collision_count() > 0:
			# if it hits a tilemap while searching, attach to it.
			for i in range(get_slide_collision_count()):
				var collision := get_slide_collision(i)
				var collider := collision.get_collider()
				if collider is TileMapLayer:
					velocity = Vector2.ZERO
					set_state(GrappleState.ATTACHED)
					player.set_movement_state(Player.MovementState.GRAPPLE)
					attached.emit()
				
func _draw():
	# draws a line between the player and the grapple point
	if not grapple_state == GrappleState.INACTIVE:
		draw_line(Vector2(), player.position - position, Color.ORANGE, 3.0)

## Throws the grapple point in a direction until in hits something
func throw(direction: Vector2) -> void:
	if not cooldown_active:
		position = player.position
		velocity = direction * player_pull_speed
		set_state(GrappleState.SEARCHING)
		grapple_cooldown.start()
	
## Handles traversal actions from the player
func handle_action(key: StringName) -> void:
	if Input.is_action_just_pressed(key):
		match grapple_state:
			GrappleState.INACTIVE:
				throw(player.global_position.direction_to(player.get_global_mouse_position()))
			_:
				cancel()
	if Input.is_action_just_released(key):
		match grapple_state:
			GrappleState.SEARCHING:
				cancel()
			GrappleState.ATTACHED:
				cancel()

## Calculates the velocity for the player when it's using this traversal method.
func calculate_frame_velocity(_delta: float) -> Vector2:
	# pull player towards grapple point
	var direction := player.position.direction_to(position)
	var distance := player.position.distance_to(position)
	
	if distance > grapple_min_pull_distance:
		return direction * grapple_point_speed
	else:
		return Vector2()

## Cancel the search.
func cancel() -> void:
	set_state(GrappleState.INACTIVE)
	player.free_movement(Player.MovementState.GRAPPLE)
	velocity = Vector2.ZERO

## Sets the state and visibility of the grapple hook.	
func set_state(new_state: GrappleState) -> void:
	grapple_state = new_state
	match grapple_state:
		GrappleState.INACTIVE:
			hide()
		_:
			show()

func _on_movement_state_changed(new_state: Player.MovementState) -> void:
	# If the movement state is set to different state while this state is active, gracefully cancel.
	if new_state != Player.MovementState.GRAPPLE and grapple_state == GrappleState.ATTACHED:
		cancel()
