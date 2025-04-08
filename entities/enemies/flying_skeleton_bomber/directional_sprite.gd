extends Node2D

var enemy: Enemy

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	assert(enemy != null, "The EnemyState state type must be used only in the enemy scene. It needs the owner to be a Enemy node.")
	
func _process(delta: float) -> void:
	set("flip_h", enemy.velocity.x > 0)
