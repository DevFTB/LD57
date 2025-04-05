extends Area2D
class_name HitboxComponent

@export var damage: int = 1

@export var repeating := false
@export var repeat_interval := 1.0

@onready var hit_timer: Timer = $HitTimer

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	hit_timer.timeout.connect(_on_hit_timer_timeout)
	
func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		area.apply_damage(damage, self)
		hit_timer.start()
		
func _on_hit_timer_timeout() -> void:
	var areas := get_overlapping_areas()
	for area in areas:
		if area is HurtboxComponent:
			area.apply_damage(damage, self)
			hit_timer.start()