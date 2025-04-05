extends Node
class_name MoabExplosionSystem

@export var time_scale: float = 1.0
@export var bomb_timer_starting_value: float = 300.0 # time in seconds for bomb to explode

var bomb_max_value: float
var bomb_timer: float:
	set(value):
		bomb_timer = clampf(value, 0, bomb_max_value)

var seconds_left: float:
	get:
		return bomb_timer / time_scale

var is_running := true
var _total_time_passed := 0.0

func _ready():
	bomb_max_value = bomb_timer_starting_value
	bomb_timer = bomb_timer_starting_value


func _process(delta):
	if is_running:
		bomb_timer -= delta * time_scale
	
	if bomb_timer <= 0:
		print("Game is over, bomb explodied sadge")
		
	_total_time_passed += delta

func add_to_timer(items_provided: int) -> void:
	var time_added := items_provided / get_items_per_second(_total_time_passed)
	bomb_timer += time_added
	print("Time added ", time_added)

func get_items_per_second(time: float) -> float:
	return pow(time, 2) / 1000000 + 0.01
