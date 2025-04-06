extends AnimationTree

@export var player: Player
@export var sprite: Sprite2D
@onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")


func _ready() -> void:
	player.jumped.connect(playback.travel.bind("jump"))
	
func _process(_delta: float) -> void:
	sprite.flip_h = player.last_inputted_direction.x > 0
	
	if player._holding_throw or playback.get_current_node().contains("throw"):
		sprite.flip_h = (player.get_global_mouse_position() - player.position).x > 0
	# aprint(playback.get_current_node())
