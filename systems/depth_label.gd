extends Label


func _on_player_depth_changed(depth):
	text = "Depth: " + str(snapped(depth,0.01)) + "m"
