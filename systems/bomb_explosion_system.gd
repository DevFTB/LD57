extends Node
class_name BombExplosionSystem

@export var time_scale: float = 1.0
@export var bomb_timer_starting_value: float = 300.0 # time in seconds for bomb to explode

var bomb_max_value: float

var bomb_timer: float:
	set(value):
		bomb_timer = clampf(value, 0, bomb_max_value)

var is_running := true

var seconds_left: float:
	get:
		return bomb_timer / time_scale

func _ready():
	#init bomb times
	bomb_max_value = bomb_timer_starting_value
	bomb_timer = bomb_timer_starting_value

	print(bomb_timer)

func _process(delta):
	if is_running:
		bomb_timer -= delta * time_scale
		print(bomb_timer)
	
	if bomb_timer <= 0:
		print("Game is over, bomb explodied sadge")