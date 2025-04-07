extends Area2D
class_name HurtboxComponent

signal damage_applied(amount: int, _source: Node)

@export var health_component: HealthComponent

func apply_damage(amount: int, _source: Node = null) -> void:
	health_component.take_damage(amount)
	damage_applied.emit(amount, _source)
