extends RangedAttack

@export var bomb_x_speed: int = 400
@export var bomb_type: BombType

var world: World
# make sure player exists all the time, otherwise this will crash!!
@onready var player: Player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	world = get_tree().get_first_node_in_group("world")

func attack():
	if player:
		var data := World.ThrowReleasedEventData.new()
		var player_position = player.global_position
		
		data.position = get_parent().enemy.global_position
		var t = abs(player_position.x - data.position.x) / bomb_x_speed
		var y_speed = ((player_position.y - data.position.y + 
			(-ProjectSettings.get_setting("physics/2d/default_gravity") * (t ** 2)/2))/t)
		
		# divide by mass of bomb, which is 1
		#print(bomb_x_speed,y_speed)
		# add a bit of randomness to the aiming
		y_speed = randf_range(y_speed * 0.8, y_speed * 1.2)
		
		data.impulse = Vector2(sign(player_position.x - data.position.x) * bomb_x_speed, y_speed) / 1
		data.bomb_type = bomb_type
		
		world._spawn_bomb_with_velocity(data)
