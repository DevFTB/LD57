extends TextureProgressBar

@export var player: Player

func _ready() -> void:
	player.throw_initiated.connect(show)
	player.throw_released.connect(hide.unbind(1))

func _process(_delta: float) -> void:
	if visible:
		ratio = player.throw_strength_curve.sample_baked(player._throw_action_held_time)
