extends CharacterBody2D
class_name GrapplePoint
signal attached

enum GrappleState {
	INACTIVE, SEARCHING, ATTACHED
}

@export var speed: float = 1000.0
@export var max_attachment_distance := 1500.0
@onready var player: Player = get_parent()

var grapple_state: GrappleState

func _ready() -> void:
	set_state(GrappleState.INACTIVE)

func throw(direction: Vector2) -> void:
	position = player.position
	velocity = direction * speed
	set_state(GrappleState.SEARCHING)
	
func _physics_process(_delta: float) -> void:
	move_and_slide()
	queue_redraw()

	if grapple_state == GrappleState.SEARCHING:
		if position.distance_to(player.position) > max_attachment_distance:
			cancel()
		elif get_slide_collision_count() > 0 and grapple_state == GrappleState.SEARCHING:
			for i in range(get_slide_collision_count()):
				var collision := get_slide_collision(i)
				var collider := collision.get_collider()
				if collider is TileMapLayer:
					velocity = Vector2.ZERO
					set_state(GrappleState.ATTACHED)
					attached.emit()
				
func cancel() -> void:
	set_state(GrappleState.INACTIVE)
	velocity = Vector2.ZERO
	
func set_state(new_state: GrappleState) -> void:
	grapple_state = new_state
	match grapple_state:
		GrappleState.INACTIVE:
			hide()
		_:
			show()

func _draw():
	if not grapple_state == GrappleState.INACTIVE:
		draw_line(Vector2(), player.position - position, Color.ORANGE, 3.0)
