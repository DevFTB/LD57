extends Node
class_name HintDisplayBox

@export var show_time: float = 3.0
@export var fifo_time: float = 1.0

@export var busy := false

@onready var label: RichTextLabel = $MarginContainer/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func show_hint(hint: Hint) -> void:
    animation_player.play("display")
    label.text = hint.hint_text
