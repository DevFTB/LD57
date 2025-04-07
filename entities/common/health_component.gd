extends Node
class_name HealthComponent

signal maximum_health_modified(new_maximum: int)

## emitted when either taking damage or healing
signal health_modified(amount: int, new_health: int)

## emitted when the current_health has dropped below 0. Only emitted once
signal died

## current_health cannot exceed this value by healing
@export var base_maximum_health: int = 5

## cannot take damage if invulnerable.
@export var is_invulnerable: bool = false

## set to true when the current_health has dropped to or past 0.
var is_dead: bool = false

@onready var maximum_health: int = base_maximum_health

@onready var current_health: int = maximum_health

	
func _ready() -> void:
	set_maximum_health(maximum_health)
	health_modified.emit(0, current_health)

func set_maximum_health(new_value: int) -> void:
	maximum_health = new_value
	maximum_health_modified.emit(maximum_health)

func heal(amount: int) -> void:
	if amount < 0:
		push_warning("Heal amount shouldn't be negative")
		return
		
	if not is_dead:
		var applied_heal = mini(amount, maximum_health - current_health)
		current_health += applied_heal
		health_modified.emit(applied_heal, current_health)

func take_damage(amount: int) -> void:
	if amount < 0:
		push_warning("Damage shouldn't be negative")
		return

	if not is_dead and not is_invulnerable:
		var applied_damage := mini(amount, current_health)
		current_health -= applied_damage
		health_modified.emit(-applied_damage, current_health)
		
		if current_health <= 0:
			is_dead = true
			died.emit()

func reset():
	is_invulnerable = false
	current_health = maximum_health
	is_dead = false
	health_modified.emit(0, maximum_health)
