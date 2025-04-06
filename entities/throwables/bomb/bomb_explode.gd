extends AnimatedSprite2D

@export var adjustment: float = 1.0
const FRAME_SIZE := 512

var radius: float
func _ready():
	var scale_factor := radius * 32 / FRAME_SIZE * adjustment
	scale = Vector2.ONE * scale_factor
	$AudioStreamPlayer2D.finished.connect(queue_free)
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.7, 1.3)
	animation_finished.connect(hide)
