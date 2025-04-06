extends Range
class_name HealthBar

@export var health_component: HealthComponent

func _ready() -> void:
	set_health_component(health_component)

func set_health_component(hc: HealthComponent) -> void:
	health_component = hc
	max_value = hc.maximum_health
	value = hc.current_health
	
	hc.health_modified.connect(_on_health_modified)
	hc.maximum_health_modified.connect(_on_maximum_health_modified)
	
func _on_health_modified(_amount: int, current_health: int) -> void:
	value = current_health
	
func _on_maximum_health_modified(maximum_health: int) -> void:
	max_value = maximum_health
