class_name LevelGen extends Node2D

@export var random_seed: int = randi()
@export var height_hardness_factor: float = 0.5
@export var ore_hardness_factor: float = 0.2
@export var navmesh_chunk_size: int = 32 ## nav mesh chunk size in tiles

@export_subgroup("Spawn Area Details")
@export var spawn_area_tilemap_topleft: Vector2i = Vector2i(-22, -116)
@export var spawn_area_tilemap_bottomright: Vector2i = Vector2i(21, -101)

# must be a multiple of 32 due to navmesh stuffs
@export var map_chunk_size = 64

@export var loot_chests_per_chunk: int = 10
@export var loot_chest_scene: PackedScene
@export var loot_tables: Array[LootTable]


@export_subgroup("Generation Extents")
@export var min_y := -100
@export var first_chunk_x := 0

# ordering determines which ones get priority when spawning
# resources must match to the row on the ore indicators atlas
enum Resources {BOMB_POWDER, UPGRADIUM}
@export var resource_threshold = [0.4, 0.5]

@onready var CAVE_BLOCK_TILEMAP: TileMapLayer = $CaveBlocks
@onready var ORE_INDICATOR_TILEMAP: TileMapLayer = $OreIndicators
@onready var CAVE_BLOCK_HARDNESS_MAP = _get_cave_block_hardness_map()
@onready var generated_chunks: Dictionary[Vector2i, bool] = {}

@onready var cave_noise = _get_cave_noise()
@onready var hardness_noise = _get_hardness_noise()
@onready var bomb_powder_ore_noise = _get_resource_map(Resources.BOMB_POWDER)
@onready var upgradium_ore_noise = _get_resource_map(Resources.UPGRADIUM)
@onready var resource_noise = {}

# TODO: will player be readied first - might rely on order of tree...
@onready var player: Player = get_tree().get_first_node_in_group("player")

var CAVE_THRESHOLD: float = -0.2
# hardness layers must be equal to len(HARDNESS_THRESHOLDS) + 1
# i think it will still work if threshold values are not unique... but make them unique anyway u stoopid
var HARDNESS_THRESHOLDS: Array[float] = [0, 0.6]
var HARDNESS_LAYER_NAME: String = "hardness"

# works ok - cellular, freq 0.1, cave threshold -0.6
# works ok - simplex, frequ 0.3, cave threshold -0.3

const UNBREAKABLE_BLOCK_SOURCE = 1
const UNBREAKABLE_BLOCK_COORDS = Vector2i(0, 1) 

func _get_cave_noise() -> Noise:
	var fast_noise: FastNoiseLite = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	#fast_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	fast_noise.seed = random_seed
	fast_noise.frequency = 0.05
	#fast_noise.frequency = 0.1
	
	return fast_noise
	
func _get_hardness_noise() -> Noise:
	var fast_noise: FastNoiseLite = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	fast_noise.seed = random_seed
	fast_noise.frequency = 0.015
	
	return fast_noise
	
func _get_resource_map(resource: Resources) -> Noise:
	# multiple resources will use this function. They all require a different noise generation
	var fast_noise: FastNoiseLite = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	fast_noise.seed = random_seed * resource
	fast_noise.frequency = 0.1
	
	return fast_noise

# TODO: might need improvement but just a POC
# TODO: transform the thresholds instead of the noise? are they equivalent?
func noise_height_transform(y: int, noise_value: float, _height_factor: float = 0.5,
	min_added: float = -2.0, max_added: float = 2.0, y_offset: float = 0.0) -> float:
	# maps from noise_value [-1, 1] to [-1, 1]
	var transform_term = clamp((_height_factor * (y + y_offset) / 100), min_added, max_added)
	return clamp(noise_value + transform_term, -1.0, 1.0)
	
func generate_cave_blocks(cave_noise: Noise, hardness_noise: Noise, resource_noise: Dictionary,
	from_x: int, to_x: int, from_y: int, to_y: int) -> void:
	# coords are tilemap coords
	for x in range(from_x, to_x + 1):
		for y in range(from_y, to_y + 1):
			var is_cave: bool = cave_noise.get_noise_2d(x, y) > CAVE_THRESHOLD
			if is_cave:
				var hardness: int = HARDNESS_THRESHOLDS.find_custom(func(e: float): return e > noise_height_transform(y, hardness_noise.get_noise_2d(x, y), height_hardness_factor)) + 1
				hardness = HARDNESS_THRESHOLDS.size() + 1 if hardness == 0 else hardness
				_add_cave_block(hardness, x, y)
				
				var ore_to_spawn = null
				for k in resource_noise.keys():
					var ore_noise = resource_noise[k].get_noise_2d(x, y)
					# change the -0.15 and 0.2 when rebalancing ore spawning lol big factors but i havent brought them out lmao
					if noise_height_transform(y, ore_noise, ore_hardness_factor, -0.15, 0.2) > resource_threshold[k] and (ore_to_spawn == null or k < ore_to_spawn):
						ore_to_spawn = k
				
				if ore_to_spawn != null:
					_add_ore_block(ore_to_spawn, x, y)
					
func generate_chests(from_x: int, to_x: int, from_y: int, to_y: int, n: int) -> void:
	# coords are tilemap coords
	var allowable_locations = get_valid_chest_locations(from_x, to_x, from_y, to_y)
	allowable_locations.shuffle()
	for i in range(n):
		if allowable_locations.is_empty():
			print("No suitable locations to spawn chest")
			break
		var spawn_loc = allowable_locations.pop_back()
		var spawn_loc_global = CAVE_BLOCK_TILEMAP.to_global(CAVE_BLOCK_TILEMAP.map_to_local(spawn_loc))
		
		spawn_chest(spawn_loc_global.x, spawn_loc_global.y, get_chest_tier(spawn_loc.x, spawn_loc.y))
		
func get_chest_tier(_x: int, y: int):
	# coords are tilemap coords
	if y < -50:
		return 0
	elif y < 0:
		return 1
	else:
		return 2
		
func spawn_chest(x: int, y: int, tier: int):
	var loot_chest = loot_chest_scene.instantiate()
	assert(tier < loot_tables.size(), "Tier " + str(tier) + " not in loot tables")
	loot_chest.loot_table = loot_tables[tier]
	add_child(loot_chest)
	loot_chest.global_position = Vector2(x, y)
	

func get_valid_chest_locations(from_x: int, to_x: int, from_y: int, to_y: int) -> Array[Vector2i]:
	var valid_chest_locations: Array[Vector2i] = []
	for x in range(from_x, to_x + 1):
		for y in range(from_y, to_y + 1):
			if is_valid_chest_location(x, y):
				valid_chest_locations.append(Vector2i(x, y))
	
	return valid_chest_locations

func is_valid_chest_location(x, y):
	var is_empty = CAVE_BLOCK_TILEMAP.get_cell_source_id(Vector2i(x, y)) == -1
	var is_on_block = CAVE_BLOCK_TILEMAP.get_cell_source_id(Vector2i(x, y + 1)) != -1
	return is_empty and is_on_block
				
func _add_cave_block(hardness: int, x: int, y: int) -> void:
	assert(CAVE_BLOCK_HARDNESS_MAP.has(hardness), "Cave block hardness map doesnt have " + str(hardness))
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	var tile_choices = CAVE_BLOCK_HARDNESS_MAP[hardness]
	var tile_choice = tile_choices[rng.randi() % tile_choices.size()]
	
	CAVE_BLOCK_TILEMAP.set_cell(Vector2i(x, y), tile_choice["source_id"], tile_choice["tile_id"])
	
func _add_ore_block(resource: Resources, x: int, y: int) -> void:
	var ORE_ATLAS_SOURCE = 0
	ORE_INDICATOR_TILEMAP.set_cell(Vector2i(x, y), ORE_ATLAS_SOURCE, Vector2i(0, resource))
	
func _get_cave_block_hardness_map() -> Dictionary:
	var valid_tiles = {}
	for source_idx in range(CAVE_BLOCK_TILEMAP.tile_set.get_source_count()):
		# all sources must be atlas sources!
		var tileset_source_id = CAVE_BLOCK_TILEMAP.tile_set.get_source_id(source_idx)
		var tileset_source: TileSetAtlasSource = CAVE_BLOCK_TILEMAP.tile_set.get_source(tileset_source_id)
		for tile_idx in range(tileset_source.get_tiles_count()):
			var tile_id = tileset_source.get_tile_id(tile_idx)
			var tile: TileData = tileset_source.get_tile_data(tile_id, 0)
			var hardness: int = tile.get_custom_data(HARDNESS_LAYER_NAME)
			if not valid_tiles.has(hardness):
				valid_tiles[hardness] = []
			valid_tiles[hardness].append({"source_id": tileset_source_id, "tile_id": tile_id})
	
	
	return valid_tiles
# The chunks where the player spawns outside of normal terrain generation
# for navmeshing---
#const START_CHUNKS := [Vector2i(0, -4), Vector2i(-1, -4)]

func generate_chunk(chunk_x: int, chunk_y: int):
	# in tilemap coords
	# chunk (0, 0) maps to topleft (-map_chunk_size/2, min_y) bottomright (map_chunk_size/2 - 1, min_y + chunk_size - 1)
	assert(map_chunk_size % 32 == 0, "Map chunk size is not a multiple of 32")
	var origin_chunk_topleft = Vector2i(-map_chunk_size/2, min_y)
	var origin_chunk_bottomright = Vector2i(map_chunk_size/2 - 1, min_y + map_chunk_size - 1)
	var chunk_offset = Vector2i(chunk_x * map_chunk_size, chunk_y * map_chunk_size)
	
	var chunk_topleft = origin_chunk_topleft + chunk_offset
	var chunk_bottomright = origin_chunk_bottomright + chunk_offset
	var min_x = chunk_topleft.x
	var max_x = chunk_bottomright.x
	var min_y = chunk_topleft.y
	var max_y = chunk_bottomright.y
	
	# base chunk
	if chunk_x == 0 and chunk_y == -1:
		#generate_unbreakable_blocks(min_x, max_x, min_y, max_y)
		generate_chunk_navmesh(min_x, max_x, min_y, max_y)
	# above ground, generate all unbreakable blocks
	if chunk_y < 0:
		if not chunk_x >= -1 and not chunk_x<= 1:
			generate_unbreakable_blocks(min_x, max_x, min_y, max_y)
	# else normal cave chunk
	else:
		generate_cave_blocks(cave_noise, hardness_noise, resource_noise, min_x, max_x, min_y, max_y)
		generate_chests(min_x, max_x, min_y, max_y, loot_chests_per_chunk)
		generate_chunk_navmesh(min_x, max_x, min_y, max_y)
	generated_chunks[Vector2i(chunk_x, chunk_y)] = true

func generate_chunk_navmesh(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	assert((max_x - min_x + 1) % navmesh_chunk_size == 0, "x range not a multiple of navmesh size")
	assert((max_y - min_y + 1) % navmesh_chunk_size == 0, "y range not a multiple of navmesh size")
	
	# +1 just to ensure it works in very small cases. not supposed to have i=max_x+1
	for x in range(min_x, max_x + 1, navmesh_chunk_size):
		# min_x=-32, max_x=31, i=-32, 0 NOT 32 (range excludes)
		for y in range(min_y, max_y + 1, navmesh_chunk_size):
			create_navmesh(x, y)

func create_navmesh(left_x: int, top_y: int):
	var right_x = left_x + navmesh_chunk_size
	var bottom_y = top_y + navmesh_chunk_size
	var new_nav_region = NavigationRegion2D.new()
	
	# TODO: local coords, not global an issue?
	$NavMeshes.add_child(new_nav_region)
	call_deferred("bake_nav_mesh", new_nav_region,
		CAVE_BLOCK_TILEMAP.map_to_local(Vector2(left_x, top_y)),
		CAVE_BLOCK_TILEMAP.map_to_local(Vector2(left_x, bottom_y)),
		CAVE_BLOCK_TILEMAP.map_to_local(Vector2(right_x, bottom_y)),
		CAVE_BLOCK_TILEMAP.map_to_local(Vector2(right_x, top_y)))
	
func generate_unbreakable_blocks(from_x: int, to_x: int, from_y: int, to_y: int) -> void:
	var base_rect := Rect2i(spawn_area_tilemap_topleft, spawn_area_tilemap_bottomright - spawn_area_tilemap_topleft + Vector2i(1, 1))
	for x in range(from_x, to_x + 1):
		for y in range(from_y, to_y + 1):
			if not base_rect.has_point(Vector2i(x, y)):
				CAVE_BLOCK_TILEMAP.set_cell(Vector2i(x, y), UNBREAKABLE_BLOCK_SOURCE, UNBREAKABLE_BLOCK_COORDS)
			
			
func get_player_chunk():
	# chunk (0, 0) maps to topleft (-map_chunk_size/2, min_y) bottomright (map_chunk_size/2 - 1, min_y + chunk_size - 1)
	var pos = player.global_position
	var player_tilemap_coords = CAVE_BLOCK_TILEMAP.local_to_map(CAVE_BLOCK_TILEMAP.to_local(pos))

	assert(map_chunk_size % 32 == 0, "Map chunk size is not a multiple of 32")
	var player_chunk_x = int(floorf(float(player_tilemap_coords.x + (map_chunk_size/2)) / float(map_chunk_size)))
	var player_chunk_y = int(floorf(float(player_tilemap_coords.y - min_y) / float(map_chunk_size)))
	
	return Vector2i(player_chunk_x, player_chunk_y)

func check_chunk_update(player_chunk_x, player_chunk_y):
	# check and generate all adjacent chunks (including diagonally)
	for i in range(-1, 2):
		for j in range(-1, 2):
			var chunk_to_check = Vector2i(player_chunk_x + i, player_chunk_y + j)
			if chunk_to_check.y >= -1 and not generated_chunks.has(chunk_to_check):
				generate_chunk(chunk_to_check.x, chunk_to_check.y)

func _ready() -> void:
	HARDNESS_THRESHOLDS.sort()
	# set globalscope seed
	seed(random_seed)

	resource_noise[Resources.UPGRADIUM] = upgradium_ore_noise
	resource_noise[Resources.BOMB_POWDER] = bomb_powder_ore_noise
	
	# base chunk
	generate_chunk(0, -1)
	# generate initial chunks below, so spawns are respected
	generate_chunk(0, 0)
	generate_chunk(-1, 0)
	generate_chunk(1, 0)
	
	# generate a few more chunks, so it doesnt lag at the start in game
	# NOTE: spawning chunks at the start seems less laggy than doing it later
	generate_chunk(-1, 1)
	generate_chunk(0, 1)
	generate_chunk(1, 1)
	
const FEATHER := 20
func bake_nav_mesh(mesh, point1, point2, point3, point4):
	var new_navigation_mesh = NavigationPolygon.new()
	var bounding_outline = PackedVector2Array([point1 - Vector2(FEATHER, FEATHER), point2 - Vector2(FEATHER, -FEATHER), point3 + Vector2(FEATHER, FEATHER), point4 + Vector2(FEATHER, -FEATHER)])
	new_navigation_mesh.add_outline(bounding_outline)
	new_navigation_mesh.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	new_navigation_mesh.agent_radius = 20
	NavigationServer2D.bake_from_source_geometry_data(new_navigation_mesh, NavigationMeshSourceGeometryData2D.new());
	mesh.navigation_polygon = new_navigation_mesh

# probably doesnt need to be run every frame, but not very expensive anyways
func _process(delta: float) -> void:
	var player_chunk = get_player_chunk()
	check_chunk_update(player_chunk.x, player_chunk.y)
