extends AnimatedSprite2D

func _ready():
	$AudioStreamPlayer2D.finished.connect(queue_free)
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.7, 1.3)
