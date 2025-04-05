class_name Enemy
extends CharacterBody2D

@export var enemy_stats : EnemyStats

@onready var refresh_timer = $RefreshTimer
@onready var nav := $NavigationAgent2D
@onready var los = $LineOfSight
@onready var state_machine = $StateMachine

var player : Player
var sees_player := false

var gravity : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")

func _ready():
	player = get_tree().get_first_node_in_group("player")
	enemy_stats.health = enemy_stats.max_health

func _process(delta):
	pass

func _physics_process(delta):
	pass

func die():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_entered():
	refresh_timer.start()


func _on_visible_on_screen_notifier_2d_screen_exited():
	refresh_timer.stop()
	state_machine._transition_to_next_state("Idle")



func _on_refresh_timer_timeout():
	#get line of sight
	#los.target_position = player.global_position
	#var collided_shape = los.get_collider()
	#if collided_shape is Player:
		#sees_player = true
	#else: 
		#sees_player = false
	#
	##start navigation agent
	#if sees_player == true:
	nav.target_position = player.global_position
	if nav.is_target_reachable():
		if enemy_stats.is_grounded:
			pass
			# grounded enemy movement
		else:
			state_machine._transition_to_next_state("Flying")
