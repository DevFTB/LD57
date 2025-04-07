extends Control

@onready var pause_menu_exit_button: Button = %PauseMenuExitButton
@onready var pause_menu_resume_button: Button = %PauseMenuResumeButton

const MAIN_MENU: PackedScene = preload("res://menu/main_menu.tscn")

func _ready() -> void:
	pause_menu_exit_button.pressed.connect(quit)
	pause_menu_resume_button.pressed.connect(set_paused.bind(false))

func quit() -> void:
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")
   
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
	
func set_paused(value: bool) -> void:
	if value:
		show()
		get_tree().paused = true
	else:
		hide()
		get_tree().paused = false
