extends RigidBody2D
class_name ThrowableBomb

signal exploded

@export var explosion_radius: int = 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var explosion_timer: Timer = $ExplosionTimer

func _ready() -> void:
#    body_entered.connect(_on_body_entered)
    explosion_timer.timeout.connect(explode)
    explosion_timer.start()
    
# func _on_body_entered(body: Node2D) -> void:
#     if body is TileMapLayer:
#         #var tilemap := body as TileMapLayer
#         explode()
#     pass

func explode() -> void:
    exploded.emit()
    animation_player.play("explode")