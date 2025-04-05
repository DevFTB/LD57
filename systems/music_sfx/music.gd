extends Node2D

@export var depth_for_track1 = 0
@export var depth_for_track2 = 100
@export var depth_for_track3 = 200



func _on_player_depth_changed(depth):
	if depth > depth_for_track1:
		$Depth1.play()
		
	pass # Replace with function body.

func fade_in(track):
	pass
