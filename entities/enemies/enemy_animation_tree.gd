extends AnimationTree

@export var enemy: Enemy
@export var sprite: Sprite2D
@onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")

func _physics_process(delta: float) -> void:
	sprite.flip_h = enemy.last_moved_direction.x > 0
