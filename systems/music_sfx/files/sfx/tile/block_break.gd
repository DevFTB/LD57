extends AnimatedSprite2D
@onready var player = $AudioStreamPlayer2D

func _ready():
	player.pitch_scale = randf_range(0.6,1.4)
	$AudioDelay.wait_time = randf_range(0.000,0.250)
	$AudioDelay.start()
	

func _on_audio_delay_timeout():
	player.play()
	$BlockBreak.emitting = true
	player.finished.connect(queue_free)
	pass # Replace with function body.
