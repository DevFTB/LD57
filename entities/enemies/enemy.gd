class_name Enemy
extends CharacterBody2D

@export var enemy_stats: EnemyStats

var player: Player
var sees_player := false
var seen_player := false

var gravity: Vector2 = Vector2(0, 250)

var last_moved_direction: Vector2 = Vector2.RIGHT

@onready var health_component: HealthComponent = $HealthComponent
@onready var refresh_timer = $RefreshTimer
@onready var nav := $NavigationAgent2D
@onready var los = $LineOfSight
@onready var state_machine = $StateMachine
@onready var animation_tree = $AnimationPlayer/AnimationTree
@onready var is_ranged = enemy_stats.range != 0


func _ready():
	player = get_tree().get_first_node_in_group("player")
	enemy_stats.health = enemy_stats.max_health
	health_component.maximum_health = enemy_stats.max_health
	health_component.current_health = health_component.maximum_health
	health_component.died.connect(die)

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass

func die():
	StatsManager.add_to_stat(StatsManager.Stat.ENEMIES_KILLED, 1)
	queue_free()

func stick(entity: Node2D) -> void:
	var _global_position := entity.global_position

	entity.get_parent().remove_child(entity)
	add_child(entity)
	
	entity.global_position = _global_position

func do_knockback(origin, amount):
	state_machine._transition_to_next_state("KnockedBack", {"knockback_origin": origin, "knockback_amount": amount})

func _on_visible_on_screen_notifier_2d_screen_entered():
	if refresh_timer:
		refresh_timer.start()


func _on_visible_on_screen_notifier_2d_screen_exited():
	refresh_timer.stop()
	state_machine._transition_to_next_state("Idle")


# TODO: perhaps refactor by moving to idle in fture. The check for idle is not great.
func _on_refresh_timer_timeout():
	#get line of sight
	los.target_position = player.global_position - global_position
	var collided_shape = los.get_collider()
	if collided_shape is Player:
		sees_player = true
		seen_player = true
	else:
		sees_player = false
	#start navigation agent
	if seen_player:
		nav.target_position = player.global_position
		if nav.is_target_reachable() and state_machine.state == $StateMachine/Idle:
			if enemy_stats.is_grounded:
				state_machine._transition_to_next_state("Running")
			else:
				state_machine._transition_to_next_state("Flying")

func _on_health_component_health_modified(amount, new_health):
	if amount < 0:
		$HurtSound.pitch_scale = randf_range(0.9, 1.1)
		$HurtSound.play()
		self.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		self.modulate = Color.WHITE

func _on_hitbox_component_hurt_entity(hurtbox_component: HurtboxComponent) -> void:
	if hurtbox_component.get_parent().is_in_group("player") and state_machine.state != $StateMachine/KnockedBack:
		do_knockback(hurtbox_component.get_parent().global_position, 1)


func _on_hurtbox_component_damage_applied(amount, _source):
	do_knockback(_source.global_position, amount / 20)
	pass # Replace with function body.
