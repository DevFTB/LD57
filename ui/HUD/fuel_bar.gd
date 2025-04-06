extends Range

@export var jetpack: Jetpack

func _ready() -> void:
	jetpack.fuel_changed.connect(update.unbind(1))
	update()

func update() -> void:
	value = jetpack.fuel
	max_value = jetpack.max_fuel
