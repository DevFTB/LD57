extends AudioStreamPlayer2D

func _ready():
	pitch_scale = randf_range(0.9,1.4)


func _on_finished():
	queue_free()
	pass # Replace with function body.
