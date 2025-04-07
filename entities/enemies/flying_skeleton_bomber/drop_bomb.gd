extends RangedAttack

@export var bomb_initial_speed: int = 0
@export var bomb_type: BombType
@export var player_raycast: RayCast2D

var world: World

func _ready() -> void:
	world = get_tree().get_first_node_in_group("world")

func attack():
	var collided_shape = player_raycast.get_collider()
	print(collided_shape)
	if collided_shape is Player:
		var data := World.ThrowReleasedEventData.new()
		
		data.position = get_parent().enemy.global_position
		data.impulse = Vector2(0, bomb_initial_speed)
		data.bomb_type = bomb_type
		
		world._spawn_bomb_with_velocity(data)
