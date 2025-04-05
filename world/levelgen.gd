extends Node2D

@export var seed: int = randi()
@export var height_hardness_factor: float = 0.5

@onready var CAVE_BLOCK_TILEMAP: TileMapLayer = $CaveBlocks
@onready var ORE_INDICATOR_TILEMAP: TileMapLayer = $OreIndicators
@onready var CAVE_BLOCK_HARDNESS_MAP = _get_cave_block_hardness_map()

var CAVE_THRESHOLD: float = -0.2
# hardness layers must be equal to len(HARDNESS_THRESHOLDS) + 1
# i think it will still work if threshold values are not unique... but make them unique anyway u stoopid
var HARDNESS_THRESHOLDS: Array[float] = [0, 0.5]
var HARDNESS_LAYER_NAME: String = "hardness"

# works ok - cellular, freq 0.1, cave threshold -0.6
# works ok - simplex, frequ 0.3, cave threshold -0.3

func _get_cave_noise() -> Noise:
	var fast_noise: FastNoiseLite = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	#fast_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	fast_noise.seed = seed
	fast_noise.frequency = 0.05
	#fast_noise.frequency = 0.1
	
	return fast_noise
	
func _get_hardness_noise() -> Noise:
	var fast_noise: FastNoiseLite = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	fast_noise.seed = seed
	fast_noise.frequency = 0.015
	
	return fast_noise
	
func _get_resource_map() -> Noise:
	# multiple resources will use this function. They all require a different noise generation
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var fast_noise: FastNoiseLite = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	fast_noise.seed = rng.randi()
	fast_noise.frequency = 0.015
	
	return fast_noise

# TODO: might need improvement but just a POC
func noise_height_transform(y: int, noise_value: float) -> float:
	# maps from noise_value [-1, 1] to [-1, 1]
	var Y_OFFSET = 0
	return clamp(noise_value + (height_hardness_factor * (y + Y_OFFSET) / 100), -1.0, 1.0)
	
func generate_cave_blocks(cave_noise: Noise, hardness_noise: Noise, 
	bomb_fuse_ore_noise: Noise, upgradium_ore_noise: Noise,
	from_x: int, to_x: int, from_y:int, to_y: int) -> void:
	# coords are tilemap coords
	for x in range(from_x, to_x):
		for y in range(from_y, to_y):
			var is_cave: bool = cave_noise.get_noise_2d(x, y) > CAVE_THRESHOLD
			if is_cave:
				var hardness: int = HARDNESS_THRESHOLDS.find_custom(func(e: float): return e > noise_height_transform(y, hardness_noise.get_noise_2d(x, y))) + 1
				hardness = HARDNESS_THRESHOLDS.size() + 1 if hardness == 0 else hardness
				_add_cave_block(hardness, x, y)
			
func _add_cave_block(hardness: int, x: int, y: int) -> void:
	assert(CAVE_BLOCK_HARDNESS_MAP.has(hardness), "Cave block hardness map doesnt have " + str(hardness))
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var tile_choices = CAVE_BLOCK_HARDNESS_MAP[hardness]
	var tile_choice = tile_choices[rng.randi() % tile_choices.size()]
	
	CAVE_BLOCK_TILEMAP.set_cell(Vector2i(x, y), tile_choice["source_id"], tile_choice["tile_id"])
	
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
	
func _ready() -> void:
	HARDNESS_THRESHOLDS.sort()
	
	var cave_noise = _get_cave_noise()
	var hardness_noise = _get_hardness_noise()
	var bomb_fuse_ore_noise = _get_resource_map()
	var upgradium_ore_noise = _get_resource_map()
	
	generate_cave_blocks(cave_noise, hardness_noise, bomb_fuse_ore_noise, upgradium_ore_noise, -100, 100, -100, 100)
	
	#for i in range(-100, 100):
		#for j in range(-100, 100):
			#print(cave_noise.get_noise_2d(i, j))
