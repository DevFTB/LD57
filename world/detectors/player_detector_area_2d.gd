extends Area2D
class_name PlayerDetectorArea2D

signal player_entered(player: Player)
signal player_interacted(player: Player, continuous_interaction_frames: int)
signal player_exited(player: Player)

var players_in_area: Array[Player]


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var bodies := get_overlapping_bodies()
	for body in bodies:
			_on_body_entered(body)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		players_in_area.append(body)
		body.interacted.connect(player_interacted.emit.bind(body))
		player_entered.emit(body)

		
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		players_in_area.erase(body)
		body.interacted.disconnect(player_interacted.emit.bind(body))
		player_exited.emit(body)
