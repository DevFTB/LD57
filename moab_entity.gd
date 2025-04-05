class_name BombTimer
extends Node2D

const BOMBPOWDER_ITEM = preload("uid://bfwwxfc0kwllo")
const UPGRADIUM_ITEM = preload("uid://bsytuw721i88d")

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetector2D

func _ready() -> void:
	player_detector.player_interacted.connect(_on_player_interacted)
	
func _on_player_interacted(player: Player) -> void:
	var player_inventory := player.inventory_component.inventory
	
	player_inventory.remove_item(BOMBPOWDER_ITEM, 1)