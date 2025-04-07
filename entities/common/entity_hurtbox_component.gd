extends HurtboxComponent

@export var blast_resistance_factor: float = 1.0

func apply_damage(amount: int, source: Node = null) -> void:
	var damage := amount

	if source is ThrowableBomb:
		damage /= floori(blast_resistance_factor)

	super.apply_damage(damage, source)
