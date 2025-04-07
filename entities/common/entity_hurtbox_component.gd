extends HurtboxComponent

@export var blast_resistance_factor: float = 0.0 ##exponential decay formula (1% decrease multiplicative in damage per 1 blast resistance factor)


func apply_damage(amount: int, source: Node = null) -> void:
	var damage := amount

	if source is ThrowableBomb:
		damage = floori(damage * pow(0.99,blast_resistance_factor))
		
	super.apply_damage(damage, source)
