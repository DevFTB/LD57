extends Node

@export var stat_bonus: int = 0
@onready var moab_explosion_system: Node = $MoabExplosionSystem
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimationPlayer/AnimatedSprite2D
@onready var world: World = $World
func _ready() -> void:
    moab_explosion_system.timeout.connect(_on_moab_timeout)

const FED_FACTOR := 20.0
func _on_moab_timeout() -> void:
    world.freeze()
    animation_player.play("game_over")

    var scale_factor: float = max(1, (StatsManager.get_stat(StatsManager.Stat.BOMBPOWDER_OFFERED) + stat_bonus) / FED_FACTOR)
    animated_sprite_2d.scale = Vector2.ONE * scale_factor
