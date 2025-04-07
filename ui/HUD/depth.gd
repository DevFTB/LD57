extends TextureRect

@export var player: Player

func _ready() -> void:
	player.depth_changed.connect(_on_player_depth_changed)

func _on_player_depth_changed(depth):
	$Label.text = str(snapped(depth, 0.01)) + "m"
