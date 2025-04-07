extends HealthBar

@export var label: Label

func set_health_component(hc: HealthComponent) -> void:
	super.set_health_component(hc)
	label.text = str(hc.current_health)
	
func _on_health_modified(amount: int, current_health: int) -> void:
	super._on_health_modified(amount, current_health)
	
	if label:
		label.text = str(health_component.current_health)
