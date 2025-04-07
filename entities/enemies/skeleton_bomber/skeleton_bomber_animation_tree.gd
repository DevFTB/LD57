extends AnimationTree
@export var enemy: CharacterBody2D
@export var sprite: Sprite2D
@onready var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")

func _physics_process(_delta: float) -> void:
	if enemy.player != null:
		sprite.flip_h = enemy.global_position.direction_to(enemy.player.global_position).x > 0
	else:
		sprite.flip_h = enemy.velocity.x > 0
# func _on_ranged_attacking_attacked() -> void:
# 	playback.travel("throw")


func _on_bomb_attack_attacked() -> void:
	playback.travel("throw")
	pass # Replace with function body.
