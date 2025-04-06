extends HealthBar

@export var label: Label

func _on_health_modified(amount: int, current_health: int) -> void:
	super._on_health_modified(amount, current_health)
	
	if label:
		label.text = str(health_component.current_health)
