extends Node2D

@onready var rope = $Line2D
@onready var rope_area = $Area2D
@onready var rope_collision = $Area2D/CollisionShape2D

var rope_x : float

var player : Player

func _ready():
	player = get_tree().get_first_node_in_group("player")
	rope_x = rope.points[0].x
	rope_collision.shape.a = rope.points[0]
func _physics_process(delta):
	if player:
		rope.points[1] = Vector2(rope_x,player.global_position.y - global_position.y + 1000)
		rope_collision.shape.b = rope.points[1]
