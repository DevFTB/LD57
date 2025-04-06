class_name MoabEntity
extends Node2D

signal consumed_item

const BOMBPOWDER_ITEM = preload("uid://bfwwxfc0kwllo")
const UPGRADIUM_ITEM = preload("uid://bsytuw721i88d")

const CONSUME_AMOUNT := 1

@export var moab_explosion_system: MoabExplosionSystem

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetector2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D

func _ready() -> void:
	player_detector.player_interacted.connect(_on_player_interacted)
	animation_player.play("idle")

func _physics_process(_delta: float) -> void:
	path_follow.progress_ratio = 1 - moab_explosion_system.bomb_timer / moab_explosion_system.bomb_max_value

func _on_player_interacted(player: Player) -> void:
	var player_inventory: Inventory = player.mineral_inventory_component.inventory
	
	if player_inventory.has_item(BOMBPOWDER_ITEM):
		player_inventory.remove_item(BOMBPOWDER_ITEM, CONSUME_AMOUNT)
		moab_explosion_system.add_to_timer(CONSUME_AMOUNT)
		
		animation_player.play("consume")
		consumed_item.emit()
