extends Control

@export var game_scene: PackedScene
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var exit_button: Button = %ExitButton
@onready var play_button: Button = %PlayButton

func _ready() -> void:
	animation_player.play("open_menu")
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(get_tree().quit)

func _on_play_pressed() -> void:
	animation_player.play("start_game")
	pass

func change_to_game() -> void:
	get_tree().change_scene_to_packed(game_scene)
