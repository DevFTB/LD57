extends Node2D

# dict of enemy scene to enemy points
@export var enemies: Dictionary[PackedScene, int]
@export var occupied_tilemap: TileMapLayer
@export var prioritise_strong_point_threshold: int = 6
#@export var spawn_point_test_indicator: TileMapLayer
@export var min_enemy_points_per_rect: int = 1
@export var max_enemy_points_per_rect: int = 14

@onready var spawn_timer = $SpawnTimer
# TODO: will player be readied first - might rely on order of tree...
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var current_enemies: Dictionary[Enemy, int] = {}
# Children of spawnzones must be collisionshape2d with rectangleshape2ds
@onready var spawn_rects = $SpawnZones.get_children().map(create_rect2_from_collisionshape2d)
@onready var rng = RandomNumberGenerator.new()

func create_rect2_from_collisionshape2d(collisionshape2d: CollisionShape2D):
	assert(collisionshape2d.shape is RectangleShape2D, "Shape of spawnzone is not rectangleshape2d")
	var half_x = float(collisionshape2d.shape.size.x) / 2
	var half_y = float(collisionshape2d.shape.size.y) / 2
	
	var pos = Vector2(collisionshape2d.position.x - half_x, collisionshape2d.position.y - half_y)
	
	return Rect2(pos, collisionshape2d.shape.size)

func is_enemy_in_spawn_rect(enemy: Enemy, spawn_rect: Rect2):
	var global_spawn_rect = Rect2(spawn_rect.position + player.global_position, spawn_rect.size)
	return global_spawn_rect.has_point(enemy.global_position)
	
func get_enemies_in_spawn_area(spawn_rect: Rect2):
	return current_enemies.keys().filter(func(e: Enemy): return is_enemy_in_spawn_rect(e, spawn_rect))

func get_spawn_rect_points(spawn_rect: Rect2):
	var points = 0
	for e in get_enemies_in_spawn_area(spawn_rect):
		points += current_enemies[e]
	
	return points

func _ready() -> void:
	#global_position = Vector2(0, 0)
	# NOTE: SPAWNER NODE MUST BE BELOW LEVEL NODE OTHERWISE FIRST SPAWN WON'T RESPECT OBSTACLES
	spawn_enemies()
	
# i've decided to implement this in terms of tilemap y, but depth value might be preferred going forward?
func get_expected_enemy_points(spawn_rect: Rect2):
	var tilemap_y = occupied_tilemap.local_to_map(occupied_tilemap.to_local(spawn_rect.position + player.global_position)).y
	# the smaller the smoother - takes longer to get from one end to another
	var SMOOTHING_FACTOR = 1.0 / 50
	
	var sigmoid = func(x, smoothing_factor): return 1 / (1.0 + exp(-smoothing_factor * x))
	
	var enemy_points = float(max_enemy_points_per_rect - min_enemy_points_per_rect) * sigmoid.call(tilemap_y, SMOOTHING_FACTOR) + min_enemy_points_per_rect
	
	return int(enemy_points)

func spawn_enemies():
	refresh_enemy_dict()
	#print("total enemies", current_enemies.keys().size())
	
	# debugging purposes only to show shapes
	$SpawnZones.global_position = player.global_position
	
	for spawn_rect in spawn_rects:
		var expected_enemy_points = get_expected_enemy_points(spawn_rect)
		#print(expected_enemy_points)
		var extra_points_req = expected_enemy_points - get_spawn_rect_points(spawn_rect)
		#print("extra points req", extra_points_req)
		if extra_points_req > 0:
			var global_rect = Rect2(spawn_rect.position + player.global_position, spawn_rect.size)
			var prioritise_strong = true if expected_enemy_points >= prioritise_strong_point_threshold else false
			spawn_enemies_in_area(extra_points_req, global_rect.position.x,
			global_rect.end.x, global_rect.position.y, global_rect.end.y, prioritise_strong)
			

func spawn_enemies_in_area(points: int, min_x: int, max_x: int, min_y: int, max_y: int, prioritise_strong: bool = false) -> void:
	var valid_spawnpoints = get_valid_spawnpoints(min_x, max_x, min_y, max_y)
	if valid_spawnpoints.size() == 0:
		print("no valid spawnpoints!")
		return
		
	var points_left = points
	while points_left > 0:
		var enemy_options = enemies.keys().filter(func(e: PackedScene): return enemies[e] < points_left)
		if enemy_options.size() == 0:
			break
		
		# weight spawns based on points if prioritise_strong else random enemy
		var new_enemy
		if prioritise_strong:
			var enemy_points = enemy_options.map(func(e): return enemies[e])
			new_enemy = enemy_options[rng.rand_weighted(enemy_points)]
		else:
			new_enemy = enemy_options.pick_random()
			
		var spawn_pos = valid_spawnpoints.pick_random()
		spawn_enemy(new_enemy, spawn_pos.x, spawn_pos.y)
		points_left -= enemies[new_enemy]
	
func get_valid_spawnpoints(min_x: int, max_x: int, min_y: int, max_y: int) -> Array[Vector2]:
	var valid_spawnpoints: Array[Vector2] = []
	var top_left = occupied_tilemap.local_to_map(occupied_tilemap.to_local(Vector2(min_x, min_y)))
	var bottom_right = occupied_tilemap.local_to_map(occupied_tilemap.to_local(Vector2(max_x, max_y)))
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			if is_valid_spawnpoint(x, y):
				var tilemap_coords = Vector2i(x, y)
				valid_spawnpoints.append(occupied_tilemap.to_global(occupied_tilemap.map_to_local(tilemap_coords)))
				#spawn_point_test_indicator.set_cell(tilemap_coords, 0, Vector2i(0, 1))
				
	return valid_spawnpoints
	
func is_valid_spawnpoint(tilemap_x: int, tilemap_y: int) -> bool:
	# checks 3x3 block around spawnpoint
	# remember that ranges dont include the last one LOL
	for i in range(-1, 2):
		for j in range(-1, 2):
			var tilemap_coords = Vector2i(tilemap_x + i, tilemap_y + j)
			if occupied_tilemap.get_cell_source_id(tilemap_coords) != -1:
				return false
	
	return true
	
	
func spawn_enemy(enemy: PackedScene, x: int, y: int):
	var enemy_node: Enemy = enemy.instantiate()
	add_child(enemy_node)
	
	enemy_node.global_position = Vector2(x, y)
	current_enemies[enemy_node] = enemies[enemy]

# TOOD: either hook up signal to enemies to remove them from array when they die or filter out dead enemies on 
# spawn timer (prolly easier tbh)

# TODO: improve this?
func refresh_enemy_dict():
	var temp_enemy_dict: Dictionary[Enemy, int] = {}
	for e in current_enemies.keys():
		if e != null:
			temp_enemy_dict[e] = current_enemies[e]
	current_enemies = temp_enemy_dict
		

func _on_spawn_timer_timeout() -> void:
	spawn_enemies()
