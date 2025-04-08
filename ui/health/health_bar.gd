extends Range
class_name HealthBar

@export var health_component: HealthComponent

func _ready() -> void:
	set_health_component(health_component)
	self.visible = false

func set_health_component(hc: HealthComponent) -> void:
	health_component = hc
	max_value = hc.maximum_health
	value = hc.current_health
	
	hc.health_modified.connect(_on_health_modified)
	hc.maximum_health_modified.connect(_on_maximum_health_modified)
	
func _on_health_modified(_amount: int, current_health: int) -> void:
	ratio = float(health_component.current_health) / float(health_component.maximum_health)
	if ratio < 1.0:
		visible = true
	
func _on_maximum_health_modified(maximum_health: int) -> void:
	max_value = maximum_health
