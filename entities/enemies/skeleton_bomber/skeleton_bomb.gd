extends ThrowableBomb

func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer or (body.is_in_group("player")):
		explode()
