extends Node2D

@export var depth_for_track1 = 10
@export var depth_for_track2 = 100
@export var depth_for_track3 = 200

var fading_tracks : Array = []

func _ready():
	for child in self.get_children():
		child.play()
		child.volume_db = -80.0

## Called on depth change to fade in tracks
func _on_player_depth_changed(depth):
	if depth < depth_for_track1:
		fade_in($Surface)
		fade_out($Depth1)
		fade_out($Depth2)
		fade_out($Depth3)
	else:
		fade_out($Surface)
		if depth > depth_for_track1:
			fade_in($Depth1)
		else:
			fade_out($Depth1)
		if depth > depth_for_track2:
			fade_in($Depth2)
		else:
			fade_out($Depth2)
		if depth > depth_for_track3:
			fade_in($Depth3)
		else:
			fade_out($Depth3)
		pass # Replace with function body.

func fade_in(audio_player : AudioStreamPlayer):
	if not fading_tracks.has(audio_player):
		var tween : Tween = create_tween()
		tween.tween_property(audio_player,"volume_db",0.0,8)
		tween.set_ease(Tween.EASE_OUT)
		fading_tracks.append(audio_player)
		tween.finished.connect(_remove_from_fade_array)

func fade_out(audio_player : AudioStreamPlayer):
	if not fading_tracks.has(audio_player):
		var tween : Tween = create_tween()
		tween.tween_property(audio_player,"volume_db",-80,8)
		tween.set_ease(Tween.EASE_OUT)
		fading_tracks.append(audio_player)
		tween.finished.connect(_remove_from_fade_array)

func _remove_from_fade_array():
	fading_tracks.remove_at(0)
	pass

func music_muted(_bool : bool):
	for child in self.get_children():
		if child is AudioStreamPlayer:
			if _bool:
				child.bus = &"Muted"
			if not _bool:
				child.bus = &"Music"
		
