extends Control
@onready var game_over_exit_button: Button = %GameOverExitButton
@onready var game_over_retry_button: Button = %GameOverRetryButton
const MAIN_MENU: PackedScene = preload("res://menu/main_menu.tscn")

func _ready() -> void:
	game_over_exit_button.pressed.connect(quit)
	game_over_retry_button.pressed.connect(retry)

func quit() -> void:
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")
   
func retry() -> void:
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().reload_current_scene()
