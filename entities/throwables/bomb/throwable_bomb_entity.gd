extends RigidBody2D
class_name ThrowableBomb

signal exploded

var bomb_type: BombType

@onready var sprite_2d: Sprite2D = $Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var explosion_timer: Timer = $ExplosionTimer
@onready var body_hitbox: HitboxComponent = $BodyHitbox
@onready var explosion_hitbox: HitboxComponent = $ExplosionHitboxComponent
@onready var ray_cast = $RayCast

@onready var explosion_animation_scene = preload("res://entities/throwables/bomb/bomb_explode.tscn")

var random_explosion_delay : bool

func _ready() -> void:
	sprite_2d.texture = bomb_type.bomb_icon
	explosion_hitbox.damage = bomb_type.entity_damage
	var new_shape: CircleShape2D = $ExplosionHitboxComponent/CollisionShape2D.shape.duplicate()
	new_shape.radius = bomb_type.explosion_radius * 32
	$ExplosionHitboxComponent/CollisionShape2D.shape = new_shape
	
	body_hitbox.body_entered.connect(_on_body_entered)
	
	body_entered.connect(_on_body_entered)
	explosion_timer.timeout.connect(explode)
	explosion_timer.start()

func _physics_process(_delta):
	ray_cast.target_position = linear_velocity * -0.05
	var collided_body = ray_cast.get_collider()
	if collided_body:
		_on_body_entered(collided_body)

	
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		if bomb_type.explode_on_impact:
			explode()
		elif bomb_type.is_sticky:
			call_deferred("set", "freeze", true)
			if body is Enemy:
				body.call_deferred("stick", self)

func explode() -> void:
	if random_explosion_delay:
		await get_tree().create_timer(randf_range(0,0.1)).timeout
	exploded.emit()
	explosion_hitbox.damage_overlapping_hurtboxes()

	var explosion_animation = explosion_animation_scene.instantiate()
	explosion_animation.radius = bomb_type.explosion_radius
	get_tree().get_first_node_in_group("world").add_child(explosion_animation)

	explosion_animation.global_position = global_position
	queue_free()
	
	#animation_player.play("explode")
