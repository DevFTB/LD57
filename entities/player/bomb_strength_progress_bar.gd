extends TextureProgressBar

@export var player: Player

@onready var sfx = $BombStrengthSFX

var random_sfx_pitch := 0.0

func _ready() -> void:
	player.throw_initiated.connect(_on_throw_initiated)
	player.throw_released.connect(_on_throw_released)

func _process(_delta: float) -> void:
	if visible:
		ratio = player.throw_strength_curve.sample_baked(player._throw_action_held_time)
		sfx.pitch_scale = ratio + 0.5 + random_sfx_pitch
		
func _on_throw_initiated():
	show()
	random_sfx_pitch = randf_range(-0.15, 0.15)
	sfx.play()
	
func _on_throw_released(data):
	sfx.stop()
	hide()
