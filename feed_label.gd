extends Label

@export var player_detector : PlayerDetectorArea2D


func _ready():
	player_detector.player_entered.connect(_on_player_entered)
	player_detector.player_exited.connect(_on_player_exited)
	
func _on_player_entered(body):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE,1)
	

func _on_player_exited(body):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0),1)
