extends Range

@export var player: Player
@onready var jetpack: Jetpack = player.jetpack

func _ready() -> void:
	player.traversal_method_unlocked.connect(update.unbind(1))
	jetpack.fuel_changed.connect(update.unbind(1))
	update()

func update() -> void:
	visible = player.unlocked_traversal_methods.has(Player.TraversalMethod.JETPACK)
	value = jetpack.fuel
	max_value = jetpack.max_fuel
