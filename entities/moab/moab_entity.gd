class_name MoabEntity
extends Node2D

signal consumed_item

const BOMBPOWDER_ITEM = preload("uid://bfwwxfc0kwllo")
const UPGRADIUM_ITEM = preload("uid://bsytuw721i88d")

const CONSUME_AMOUNT := 1

@export var moab_explosion_system: MoabExplosionSystem

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetector2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	player_detector.player_interacted.connect(_on_player_interacted)
	
func _on_player_interacted(player: Player) -> void:
	var player_inventory: Inventory = player.mineral_inventory_component.inventory
	
	if player_inventory.has_item(BOMBPOWDER_ITEM):
		player_inventory.remove_item(BOMBPOWDER_ITEM, CONSUME_AMOUNT)
		moab_explosion_system.add_to_timer(CONSUME_AMOUNT)
		
		animation_player.play("consume")
		consumed_item.emit()
