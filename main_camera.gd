extends Camera2D


@export var random_camera_shake_strength := 30.0
@export var shake_fade: float = 5.0
@export var max_shake_strength := 10.0
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
