extends Node
class_name MoabExplosionSystem

@export var time_scale: float = 1.0
@export var bomb_timer_starting_value: float = 300.0 # time in seconds for bomb to explode
@export var bomb_danger_seconds_left = 60.0 # time in seconds for danger mode

var current_danger_mode = false

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
	
	# if bomb_timer <= 0:
	# 	print("Game is over, bomb explodied sadge")
		
	_total_time_passed += delta
	
	if seconds_left < bomb_danger_seconds_left:
		if current_danger_mode == false:
			current_danger_mode = true
			var bomb_tween = get_tree().create_tween()
			$BombDangerSound.play()
			$"../Music".music_muted(true)
		$BombDangerSound.pitch_scale = 1.5 - (seconds_left / bomb_danger_seconds_left)
	elif seconds_left >= bomb_danger_seconds_left : 
		current_danger_mode = false
		$BombDangerSound.stop()
		$BombDangerSound.pitch_scale = 0.5
		$"../Music".music_muted(false)


func add_to_timer(items_provided: int) -> void:
	var time_added := items_provided / get_items_per_second(_total_time_passed)
	bomb_timer += time_added

func get_items_per_second(time: float) -> float:
	return pow(time, 2) / 1000000 + 0.01
