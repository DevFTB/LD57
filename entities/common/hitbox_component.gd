extends Area2D
class_name HitboxComponent

signal hurt_entity(hurtbox_component, damage: int)

@export var active: bool = true
@export var damage: int = 1
@export var damage_distance_curve : Curve
@export var repeating := false
@export var repeat_interval := 1.0
@export var has_dmg_falloff := false

@onready var hit_timer: Timer = $HitTimer

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	hit_timer.timeout.connect(_on_hit_timer_timeout)
	#hurt_entity.connect(_print_hurt_entity)

func _on_area_entered(area: Area2D) -> void:
	if active and area is HurtboxComponent:
		area.apply_damage(damage, get_parent())
		hurt_entity.emit(area, damage)
		if repeating:
			hit_timer.start()

func damage_overlapping_hurtboxes() -> void:
	var areas := get_overlapping_areas()
	for area in areas:
		if area is HurtboxComponent:
			var damage_amount = damage
			if has_dmg_falloff:
				var max_range = $CollisionShape2D.shape.radius
				var distance_to_area: float = self.global_position.distance_to(area.global_position)
				
				damage_amount = damage_distance_curve.sample_baked(clampf((1 - (distance_to_area / max_range)), 0.0, 1.0)) * damage

			area.apply_damage(damage_amount, get_parent())
			hurt_entity.emit(area, damage)
			if repeating:
				hit_timer.start()
		
func _on_hit_timer_timeout() -> void:
	if active:
		damage_overlapping_hurtboxes()

func _print_hurt_entity(hb: HurtboxComponent, damage: int) -> void:
	print("%s hurt %s for %d damage" % [get_parent().name, hb.get_parent().name, damage])
