extends Node2D

@onready var player: Player = $Player
@onready var tilemap: TileMapLayer = $Level/CaveBlocks

func _ready() -> void:
	player.throw_initiated.connect(_spawn_bomb_with_velocity)


func _spawn_bomb_with_velocity(data: Player.ThrowInitiatedEventData) -> void:
	var new_bomb := data.bomb_type.bomb_scene.instantiate() as ThrowableBomb
	new_bomb.bomb_type = data.bomb_type
	
	add_child(new_bomb)
	new_bomb.global_position = data.impulse.normalized() * 30 + data.position
	new_bomb.apply_central_impulse(data.impulse)
	
	new_bomb.exploded.connect(_on_bomb_exploded.bind(new_bomb))
	print(data.impulse)

func _on_bomb_exploded(bomb: ThrowableBomb) -> void:
	var explosion_radius := bomb.bomb_type.explosion_radius

	var map_position_of_explosion = tilemap.local_to_map(bomb.global_position)
	var top_left = map_position_of_explosion - Vector2i.ONE * explosion_radius
	var bottom_right = map_position_of_explosion + Vector2i.ONE * explosion_radius

	var explosion_tiles: Array[Vector2i] = []
	for x: int in range(top_left.x, bottom_right.x + 1):
		for y: int in range(top_left.y, bottom_right.y + 1):
			var distance: float = pow((x - map_position_of_explosion.x), 2) + pow(y - map_position_of_explosion.y, 2)
			prints(x, y, distance, map_position_of_explosion)
			if distance < pow(explosion_radius, 2) - 1.0:
				explosion_tiles.append(Vector2i(x, y))

	for tile in explosion_tiles:
		var tile_data: TileData = tilemap.get_cell_tile_data(tile)
		if tile_data:
			var tile_hardness: int = tile_data.get_custom_data("hardness")
			if tile_hardness >= 0 and tile_hardness <= bomb.bomb_type.hardness:
				tilemap.set_cell(tile)
