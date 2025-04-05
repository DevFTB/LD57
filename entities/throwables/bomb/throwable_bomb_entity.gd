extends RigidBody2D
class_name ThrowableBomb

signal exploded

var bomb_type: BombType

@onready var sprite_2d: Sprite2D = $Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var explosion_timer: Timer = $ExplosionTimer
@onready var hitbox_component: HitboxComponent = $HitboxComponent

func _ready() -> void:
	sprite_2d.texture = bomb_type.bomb_icon
	hitbox_component.damage = bomb_type.entity_damage
	var new_shape: CircleShape2D = $HitboxComponent/CollisionShape2D.shape.duplicate()
	new_shape.radius = bomb_type.explosion_radius * 32
	$HitboxComponent/CollisionShape2D.shape = new_shape
	
	body_entered.connect(_on_body_entered)
	explosion_timer.timeout.connect(explode)
	explosion_timer.start()
	
func _on_body_entered(body: Node2D) -> void:
	if bomb_type.is_sticky:
		if body is TileMapLayer:
			call_deferred("set", "freeze", true)

func explode() -> void:
	exploded.emit()
	hitbox_component.damage_overlapping_hurtboxes()
	animation_player.play("explode")
