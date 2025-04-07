extends Camera2D
class_name MainCamera

const SPAWN_ZOOM := Vector2(2.0, 2.0)

@export var random_camera_shake_strength := 30.0
@export var shake_fade: float = 5.0
@export var max_shake_strength := 10.0

var current_tween: Tween

var camera_shake_strength: float:
	set(value):
		camera_shake_strength = clamp(value, 0, max_shake_strength)

func apply_shake():
	camera_shake_strength = random_camera_shake_strength

func _physics_process(delta):
	if camera_shake_strength > 0:
		camera_shake_strength = lerpf(camera_shake_strength, 0, shake_fade * delta)
		offset = randomise_camera_offset()
	
func randomise_camera_offset() -> Vector2:
	return Vector2(randf_range(-camera_shake_strength, camera_shake_strength), randf_range(-camera_shake_strength, camera_shake_strength))

func focus_on(node: Node2D, duration: float) -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "global_position", node.global_position, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	current_tween.tween_property(self, "zoom", SPAWN_ZOOM, duration)
