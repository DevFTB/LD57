extends ProgressBar

@export var bomb_explosion_system: MoabExplosionSystem
@export var bomb_progress_bar: ProgressBar
@export var time_display: Label

signal changed_danger_mode(_bool)

var current_danger_mode := false

func _process(_delta: float) -> void:
	var minutes := floorf(bomb_explosion_system.time_left / 60)
	var seconds := floorf(bomb_explosion_system.time_left - (minutes * 60))

	bomb_progress_bar.max_value = bomb_explosion_system.bomb_max_value
	bomb_progress_bar.value = bomb_explosion_system.bomb_timer

	time_display.text = "%d:%02d" % [minutes, seconds]
