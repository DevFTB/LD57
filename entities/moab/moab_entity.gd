class_name MoabEntity
extends Node2D

signal consumed_item


const BOMBPOWDER_ITEM = preload("uid://bfwwxfc0kwllo")
const UPGRADIUM_ITEM = preload("uid://bsytuw721i88d")

const CONSUME_AMOUNT := 1

@export var moab_explosion_system: MoabExplosionSystem
@export var feed_curve: Curve

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetector2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var playback: AnimationNodeStateMachinePlayback = $AnimationPlayer/AnimationTree.get("parameters/playback")
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D

func _ready() -> void:
	player_detector.player_interacted.connect(_on_player_interacted)
	animation_player.play("idle")

func _physics_process(_delta: float) -> void:
	path_follow.progress_ratio = 1 - moab_explosion_system.bomb_timer / moab_explosion_system.bomb_max_value

func _on_player_interacted(continuous_interaction_frames: int, player: Player) -> void:
	if (continuous_interaction_frames - 1) % 20 == 0:
		var player_inventory: Inventory = player.mineral_inventory_component.inventory

		var seconds_held: float = float(continuous_interaction_frames) / float(ProjectSettings.get("physics/common/physics_ticks_per_second"))
		seconds_held = minf(feed_curve.max_domain, seconds_held)
		var consume_amount = floori(feed_curve.sample_baked(seconds_held))
		var consume_int := mini(player_inventory.get_item_amount(BOMBPOWDER_ITEM), consume_amount)

		if consume_int > 0:
			player_inventory.remove_item(BOMBPOWDER_ITEM, consume_int)
			moab_explosion_system.add_to_timer(consume_int)
			
			StatsManager.add_to_stat(StatsManager.Stat.BOMBPOWDER_OFFERED, consume_int)
			
			playback.travel("consume")
			$EatSound.play()
			consumed_item.emit()

func self_destruct() -> void:
	pass
