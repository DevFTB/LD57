extends Node2D

@onready var player: Player = $Player
@onready var tilemap: TileMapLayer = $Level/CaveBlocks
@onready var nav_meshes = $Level/NavMeshes

func _ready() -> void:
	player.throw_released.connect(_spawn_bomb_with_velocity)


func _spawn_bomb_with_velocity(data: Player.ThrowReleasedEventData) -> void:
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
	
	# Generates a bounding rectangle for the explosion.
	var top_left = map_position_of_explosion - Vector2i.ONE * explosion_radius
	var bottom_right = map_position_of_explosion + Vector2i.ONE * explosion_radius

	var explosion_tiles: Array[Vector2i] = []
	for x: int in range(top_left.x, bottom_right.x + 1):
		for y: int in range(top_left.y, bottom_right.y + 1):
			# Calculate distance to center of explosion
			var distance: float = sqrt(pow((x - map_position_of_explosion.x), 2) + pow(y - map_position_of_explosion.y, 2))
			
			# Checks in a circle around the center
			if distance < explosion_radius:
				var tile_location := Vector2i(x, y)
				var tile_data: TileData = tilemap.get_cell_tile_data(tile_location)
				if tile_data:
					var tile_hardness: int = tile_data.get_custom_data("hardness")
					
					# The bombs hardness falls of linearly as it gets further away from the center
					var bomb_effective_hardness = clampf((1 - distance / explosion_radius) * bomb.bomb_type.hardness, 0, bomb.bomb_type.hardness)

					# If the tile isn't indestructible and the bomb is strong enough, flag the tile to be broken.
					if tile_hardness >= 0 and tile_hardness <= bomb_effective_hardness:
						explosion_tiles.append(Vector2i(x, y))

	
	for tile in explosion_tiles:
		tilemap.set_cell(tile)
	
	for nav_mesh in nav_meshes.get_children():
		var baked_nav_mesh: Array = []
		if nav_mesh is NavigationRegion2D:
			var outline = nav_mesh.get_bounds()
			var bounding_box = outline.grow(100)
			for tile in explosion_tiles:
				if bounding_box.has_point(tilemap.map_to_local(tile)):
					if not baked_nav_mesh.has(nav_mesh):
						baked_nav_mesh.append(nav_mesh)
						nav_mesh.bake_navigation_polygon()
