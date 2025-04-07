extends Control

@export var spawn_area_detector: PlayerDetectorArea2D

var toggleable := true

func _ready() -> void:
	if spawn_area_detector:
		spawn_area_detector.player_entered.connect(set_toggleable.bind(true).unbind(1))
		spawn_area_detector.player_exited.connect(set_toggleable.bind(false).unbind(1))
	else:
		push_error("No spawn area detector assigned to upgrade GUI")
	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_released("toggle_upgrade_gui"):
		if toggleable:
			visible = not visible
			get_tree().paused = visible

func set_toggleable(value: bool) -> void:
	toggleable = value
	if not toggleable:
		visible = false
