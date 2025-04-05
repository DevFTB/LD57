extends RigidBody2D
class_name ThrowableBomb

signal exploded

@export var explosion_radius: int = 1

var bomb_type: BombType

@onready var sprite_2d: Sprite2D = $Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var explosion_timer: Timer = $ExplosionTimer

func _ready() -> void:
	sprite_2d.texture = bomb_type.bomb_icon
	body_entered.connect(_on_body_entered)
	explosion_timer.timeout.connect(explode)
	explosion_timer.start()
	
func _on_body_entered(body: Node2D) -> void:
	if bomb_type.is_sticky:
		if body is TileMapLayer:
			call_deferred("set", "freeze", true)

func explode() -> void:
	exploded.emit()
	animation_player.play("explode")
