extends Node

# dict of enemy scene to enemy points
@export var enemies: Dictionary[PackedScene, int]
@export var occupied_tilemap: TileMapLayer

@onready var spawn_timer = $SpawnTimer
# TODO: will player be readied first - might rely on order of tree...
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var current_enemies: Dictionary[Enemy, int] = {}
# Children of spawnzones must be collisionshape2d with rectangleshape2ds
@onready var spawn_rects = $SpawnZones.get_children().map(create_rect2_from_collisionshape2d)

func create_rect2_from_collisionshape2d(collisionshape2d: CollisionShape2D):
	assert(collisionshape2d.shape is RectangleShape2D, "Shape of spawnzone is not rectangleshape2d")
	var half_x = float(collisionshape2d.shape.size.x) / 2
	var half_y = float(collisionshape2d.shape.size.y) / 2
	
	var position = Vector2(collisionshape2d.position.x - half_x, collisionshape2d.position.y - half_y)
	
	return Rect2(position, collisionshape2d.shape.size)

func is_enemy_in_spawn_rect(enemy: Enemy, spawn_rect: Rect2):
	var global_spawn_rect = Rect2(spawn_rect.position + player.global_position, spawn_rect.size)
	return global_spawn_rect.has_point(enemy.global_position)
	
func get_enemies_in_spawn_area(spawn_rect: Rect2):
	return current_enemies.keys().map(func(e: Enemy): return is_enemy_in_spawn_rect(e, spawn_rect))

func get_spawn_rect_points(spawn_rect: Rect2):
	var points = 0
	for e in get_enemies_in_spawn_area(spawn_rect):
		points += current_enemies[e]
	
	return points

#func _ready() -> void:
	#print(spawn_rects)
	
func get_expected_enemy_points(spawn_rect: Rect2):
	return 10

func spawn_enemies():
	refresh_enemy_dict()
	
	for spawn_rect in spawn_rects:
		var extra_points_req = get_expected_enemy_points(spawn_rect) - get_spawn_rect_points(spawn_rect)
		if extra_points_req > 0:
			var global_rect = Rect2(spawn_rect.position + player.global_position, spawn_rect.size)
			spawn_enemies_in_area(extra_points_req, global_rect.position.x,
			global_rect.end.x, global_rect.end.y,global_rect.end.y)
			

func spawn_enemies_in_area(points: int, min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var valid_spawnpoints = get_valid_spawnpoints(min_x, max_x, min_y, max_y)
	if valid_spawnpoints.size() == 0:
		print("no valid spawnpoints!")
		return
		
	var points_left = points
	while points_left > 0:
		var enemy_options = enemies.keys().filter()
	
func get_valid_spawnpoints(min_x: int, max_x: int, min_y: int, max_y: int) -> Array[Vector2]:
	var valid_spawnpoints: Array[Vector2] = []
	var top_left = occupied_tilemap.local_to_map(Vector2(min_x, min_y))
	var bottom_right = occupied_tilemap.local_to_map(Vector2(max_x, max_y))
	for x in range(top_left.x, top_left.y):
		for y in range(bottom_right.x, bottom_right.y):
			var tilemap_coords = Vector2i(x, y)
			var cell = occupied_tilemap.get_cell_source_id(tilemap_coords)
			if cell == -1:
				valid_spawnpoints.append(occupied_tilemap.map_to_local(tilemap_coords))
	
	return valid_spawnpoints
	
	
func spawn_enemy(enemy: PackedScene, x: int, y: int):
	var enemy_node: Enemy = enemy.instantiate()
	add_child(enemy_node)
	enemy_node.global_position = Vector2(x, y)
	current_enemies[enemy_node] = enemies[enemy]

# TOOD: either hook up signal to enemies to remove them from array when they die or filter out dead enemies on 
# spawn timer (prolly easier tbh)

func refresh_enemy_dict():
	for e in current_enemies.keys():
		if e == null:
			current_enemies.erase(e)
		


func _on_spawn_timer_timeout() -> void:
	spawn_enemies()
