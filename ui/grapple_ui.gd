extends "res://ui/timer_progress_bar.gd"

@export var player : Player

func _ready() -> void:
	super._ready()
	player.traversal_method_unlocked.connect(update)

func update() -> void:
	super.update()
	visible = player.unlocked_traversal_methods.has(Player.TraversalMethod.GRAPPLE)
