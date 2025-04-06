extends AnimatedSprite2D

func _ready():
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.7,1.3)



func _on_audio_stream_player_2d_finished():
	queue_free()
