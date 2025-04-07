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
@onready var animation_tree = get_node_or_null("AnimationPlayer/AnimationTree")
@onready var is_ranged = enemy_stats.range != 0
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var death_scene = preload("res://entities/enemies/bat/death.tscn")
func _ready():
	player = get_tree().get_first_node_in_group("player")
	if enemy_stats.hurt_sound:
		$HurtSound.stream = enemy_stats.hurt_sound
	enemy_stats.health = enemy_stats.max_health
	health_component.maximum_health = enemy_stats.max_health
	health_component.current_health = health_component.maximum_health

	health_component.died.connect(die)
	health_component.health_modified.connect(_on_health_component_health_modified)

	hurtbox_component.damage_applied.connect(_on_hurtbox_component_damage_applied)
	hitbox_component.hurt_entity.connect(_on_hitbox_component_hurt_entity)
	
	refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass

func die():
	StatsManager.add_to_stat(StatsManager.Stat.ENEMIES_KILLED, 1)
	call_deferred("_spawn_death_scene")
	
	queue_free()
	
func _spawn_death_scene() -> void:
	var death = death_scene.instantiate()
	get_tree().get_first_node_in_group("world").add_child(death)
	death.global_position = self.global_position
	var death_initial_velocity = Vector2(randf_range(-100, 100), randf_range(-100, -300))
	death.set_properties(enemy_stats.death_sound, enemy_stats.death_sprite, death_initial_velocity, enemy_stats.death_sprite_scale)


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
		# dirty hack, ususally navs towards player, but for flying skeleton bomber
		# we want it to bomb from above
		var is_flying_skeleton_bomber = enemy_stats.resource_name == "flying_skeleton_stats"
		var flying_skeleton_target = player.global_position + Vector2(0, -224)
		nav.target_position = player.global_position if not is_flying_skeleton_bomber else flying_skeleton_target
		# another dirty hack here, because flying skeleton not always target reachable, but we want it to try get as close as possible anyways
		if (nav.is_target_reachable() and state_machine.state == $StateMachine/Idle) or (is_flying_skeleton_bomber and state_machine.state == $StateMachine/Idle):
			if enemy_stats.is_grounded:
				state_machine._transition_to_next_state("Running")
			else:
				state_machine._transition_to_next_state("Flying")

func _on_health_component_health_modified(amount, _new_health):
	if amount < 0:
		$HurtSound.pitch_scale = randf_range(0.9, 1.1)
		$HurtSound.play()
		self.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		self.modulate = Color.WHITE

func _on_hitbox_component_hurt_entity(hurtbox_component: HurtboxComponent, _damage: float) -> void:
	if hurtbox_component.get_parent().is_in_group("player") and state_machine.state != $StateMachine/KnockedBack:
		do_knockback(hurtbox_component.get_parent().global_position, 1)


func _on_hurtbox_component_damage_applied(amount, _source):
	if amount > 5:
		do_knockback(_source.global_position, amount / 20)
	pass # Replace with function body.
