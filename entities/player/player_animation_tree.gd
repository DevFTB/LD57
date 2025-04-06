extends AnimationTree

@export var player: Player
@export var sprite: Sprite2D
@onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")


func _ready() -> void:
	player.jumped.connect(playback.travel.bind("jump"))
	player.throw_released.connect(playback.travel.bind("throw").unbind(1))
	
func _process(_delta: float) -> void:
	sprite.flip_h = player.velocity.x > 0
	# print(playback.get_current_node())
