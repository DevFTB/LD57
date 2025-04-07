extends AnimationTree

@export var player: Player
@export var health_component: HealthComponent
@export var sprite: Sprite2D
@onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")

func _ready() -> void:
	player.jumped.connect(playback.travel.bind("jump"))
	player.died.connect(_on_player_died)
	health_component.health_modified.connect(_on_player_health_modified)
	
func _process(_delta: float) -> void:
	sprite.flip_h = player.last_inputted_direction.x > 0
	
	if player._holding_throw or playback.get_current_node().contains("throw"):
		sprite.flip_h = (player.get_global_mouse_position() - player.position).x > 0
	#print(playback.get_current_node())

func _on_player_health_modified(amount: int, _new_value: int) -> void:
	if amount < 0:
		playback.travel("hurt")

func _on_player_died() -> void:
	playback.travel("death")
