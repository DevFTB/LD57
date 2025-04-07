extends RigidBody2D
class_name Death

func set_properties(death_sound: AudioStream, texture: Texture2D, initial_velocity: Vector2):
	$DeathSound.stream = death_sound
	$DeathSound.play()
	$Sprite.texture = texture
	$Timer.start()
	
	linear_velocity = initial_velocity

	
func _on_timer_timeout():
	queue_free()
	pass # Replace with function body.
