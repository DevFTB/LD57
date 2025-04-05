class_name BombTimer
extends Node2D

@onready var bomb_progress_bar = $BombProgressBar
@onready var time_display = $TimeDisplay

@export var time_scale : float = 1
@export var bomb_timer_starting_value : float = 300 #time in seconds for bomb to explode

var bomb_max_value : float
var bomb_timer : float:
	set(value) : clamp(value, 0, bomb_max_value)

var is_running = true

func _ready():
	#init bomb times
	bomb_timer = bomb_timer_starting_value
	bomb_max_value = bomb_timer_starting_value
	
func _process(delta):
	if is_running:
		bomb_timer -= delta * time_scale
	#updates progress bar
	bomb_progress_bar.max_value = bomb_max_value
	bomb_progress_bar.value = bomb_timer
	
	#updates time text
	var bomb_time_left = bomb_timer / time_scale
	var minutes = floor(bomb_time_left / 60)
	var seconds = floor(bomb_time_left - (minutes * 60))
	time_display.text = (str(int(minutes)) + ":" + str(int(seconds)))

	if bomb_timer <= 0:
		print("Game is over, bomb explodied sadge")
