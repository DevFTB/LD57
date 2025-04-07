class_name EnemyStats
extends Resource

@export var max_health: int = 100
@export var move_speed: int = 500
#@export var damage: float = 10
# melee enemies have range 0, ranged enemies have range > 0
# range determines how far the enemies stay away from players
# and whether RangedAttack state is used
@warning_ignore("shadowed_global_identifier")
@export var range: float = 0
@export var is_grounded: bool = false

@export var hurt_sound: AudioStream
@export var death_sound: AudioStream
@export var death_sprite: Texture2D
@export var death_sprite_scale: Vector2 = Vector2(0.5, 0.5)

var health: float:
	set(value): clamp(value, 0, max_health)
