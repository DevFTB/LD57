extends TextureRect



func _on_player_depth_changed(depth):
	$Label.text = str(snapped(depth, 0.01)) + "m"
	pass # Replace with function body.
