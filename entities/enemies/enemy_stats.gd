class_name EnemyStats
extends Resource

@export var max_health : float = 100
@export var move_speed : int = 500
@export var damage : float = 10
@export var is_grounded : bool = false

var health : float:
	set(value) : clamp(value, 0 , max_health)
