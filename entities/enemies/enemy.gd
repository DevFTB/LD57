class_name Enemy
extends CharacterBody2D

@export var enemy_stats: EnemyStats

var player: Player
var sees_player := false

var gravity: Vector2 = Vector2(0, 250)

@onready var health_component: HealthComponent = $HealthComponent
@onready var refresh_timer = $RefreshTimer
@onready var nav := $NavigationAgent2D
@onready var los = $LineOfSight
@onready var state_machine = $StateMachine


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
	queue_free()

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
	#start navigation agent
	if sees_player == true:
		nav.target_position = player.global_position
		if nav.is_target_reachable() and state_machine.state == $StateMachine/Idle:
			if enemy_stats.is_grounded:
				state_machine._transition_to_next_state("Running")
			else:
				state_machine._transition_to_next_state("Flying")
