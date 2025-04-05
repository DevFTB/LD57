class_name BombTimer
extends Node2D

@onready var bomb_timer = %BombTimer

@export var bomb_timer_starting_value : float = 300 #time in seconds for bomb to explode

var bomb_max_time : float

func _ready():
	bomb_timer.wait_time = bomb_timer_starting_value
	bomb_timer.start()
	
func _process(delta):
	pass
