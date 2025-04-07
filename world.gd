class_name World extends Node2D


@export var spawn_camera_offset: Vector2 = Vector2(0, -30)

## Everytime the player enters spawn their bomb inventory will have atleast this many of each item
@export var restock_inventory: Inventory
@export var base_zoom = 1.5
@export var spawn_zoom = 2.0
@export var shake_intensity := 2.0

@export var hardness_ore_drops: Dictionary[int, RandomInt] = {}
@export var moab: Node2D

@onready var player: Player = $Player
@onready var cave_blocks_tilemap: TileMapLayer = $Level/CaveBlocks
@onready var ore_tilemap: TileMapLayer = $Level/OreIndicators
@onready var nav_meshes = $Level/NavMeshes
@onready var camera = $MainCamera
@onready var winch = $Winch

@onready var block_break_scene = preload("res://systems/music_sfx/files/sfx/tile/block_break.tscn")

enum CameraMode {FOLLOWING_PLAYER, SPAWN_ROOM_STATIC, FROZEN, INITIAL}
var initial_camera_location: Vector2
var queued_camera_mode
var current_camera_mode = CameraMode.FOLLOWING_PLAYER


class ThrowReleasedEventData:
	var position: Vector2
	var impulse: Vector2
	var bomb_type: BombType
	var random_fuse: bool = false
	
func _ready() -> void:
	player.throw_released.connect(_spawn_bomb_with_velocity)
	player.health_component.died.connect(_on_player_death)
	initial_camera_location = camera.position
	
func _physics_process(_delta):
	match current_camera_mode:
		CameraMode.FOLLOWING_PLAYER:
			var camera_tweener = get_tree().create_tween()
			camera_tweener.parallel().tween_property(camera, "zoom", Vector2(base_zoom, base_zoom), 0.1)
			camera_tweener.set_ease(Tween.EASE_IN)
			camera_tweener.parallel().tween_property(camera, "global_position", player.global_position, 0.3)
		CameraMode.SPAWN_ROOM_STATIC:
			pass

func freeze() -> void:
	current_camera_mode = CameraMode.FROZEN
	player.freeze()
	pass

func switch_camera_mode(requested_camera_mode):
	if requested_camera_mode is CameraMode:
		current_camera_mode = requested_camera_mode
	else:
		assert("Camera Error - " + str(requested_camera_mode) + " does not exist.")

func process_camera():
	match current_camera_mode:
		CameraMode.SPAWN_ROOM_STATIC:
			var camera_tweener = get_tree().create_tween()
			camera_tweener.set_ease(Tween.EASE_IN_OUT)
			camera_tweener.set_trans(Tween.TRANS_CUBIC)
			camera_tweener.parallel().tween_property(camera, "zoom", MainCamera.SPAWN_ZOOM, 1)
			camera_tweener.parallel().tween_property(camera, "position", initial_camera_location + spawn_camera_offset, 1)
		CameraMode.INITIAL:
			current_camera_mode = CameraMode.FOLLOWING_PLAYER
	pass

func _spawn_bomb_with_velocity(data: ThrowReleasedEventData) -> void:
	var new_bomb := data.bomb_type.bomb_scene.instantiate() as ThrowableBomb
	new_bomb.bomb_type = data.bomb_type
	
	add_child(new_bomb)
	new_bomb.global_position = data.impulse.normalized() * 30 + data.position
	new_bomb.apply_central_impulse(data.impulse)
	if data.random_fuse:
		new_bomb.random_explosion_delay = true
	new_bomb.exploded.connect(_on_bomb_exploded.bind(new_bomb))
	
func _tween_to_moab() -> void:
	camera.focus_on(moab, 2.0)
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes

func _on_bomb_exploded(bomb: ThrowableBomb) -> void:
	camera.random_camera_shake_strength = bomb.bomb_type.explosion_radius * bomb.bomb_type.hardness * shake_intensity
	camera.apply_shake()
	var explosion_radius := bomb.bomb_type.explosion_radius

	var map_position_of_explosion = cave_blocks_tilemap.local_to_map(bomb.global_position)
	
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
				var tile_data: TileData = cave_blocks_tilemap.get_cell_tile_data(tile_location)
				if tile_data:
					var tile_hardness: int = tile_data.get_custom_data("hardness")
					
					# The bombs hardness falls of linearly as it gets further away from the center
					var bomb_effective_hardness = clampf((1 - distance / explosion_radius) * bomb.bomb_type.hardness, 0, bomb.bomb_type.hardness)

					# If the tile isn't indestructible and the bomb is strong enough, flag the tile to be broken.
					if tile_hardness >= 0 and tile_hardness <= bomb_effective_hardness:
						explosion_tiles.append(Vector2i(x, y))
	
	var tiles_remaining := explosion_tiles.size()
	var index := 0

	while tiles_remaining > MAX_TILES_PER_FRAME:
		print("NEW CHUNK")
		var take := mini(MAX_TILES_PER_FRAME, tiles_remaining)
		tiles_remaining -= take

		var tiles := explosion_tiles.slice(index * MAX_TILES_PER_FRAME, index * MAX_TILES_PER_FRAME + take)
		_destroy_tiles(tiles, false, false, true)

		index += 1
		await get_tree().physics_frame
	
	_destroy_tiles(explosion_tiles.slice(index * MAX_TILES_PER_FRAME, index * MAX_TILES_PER_FRAME + tiles_remaining))
	
const MAX_TILES_PER_FRAME := 300

func _destroy_tiles(explosion_tiles: Array[Vector2i], rebake := true, animate := true, chunk_items := false) -> void:
	var inventory: Inventory = Inventory.new()
	for tile in explosion_tiles:
		var has_ore := ore_tilemap.get_cell_source_id(tile) != -1
		# check for drops
		if has_ore:
			var location = ore_tilemap.map_to_local(tile)
			var item: Item = ore_tilemap.get_cell_tile_data(tile).get_custom_data("drop_item")

			var hardness: int = cave_blocks_tilemap.get_cell_tile_data(tile).get_custom_data("hardness")
			var drop_amount: int = hardness_ore_drops[hardness].sample() if hardness_ore_drops.has(hardness) else 1
			
			if item.id == &"bombpowder":
				StatsManager.add_to_stat(StatsManager.Stat.BOMBPOWDER_MINED, drop_amount)

			if item.id == &"upgradium":
				StatsManager.add_to_stat(StatsManager.Stat.UPGRADIUM_MINED, drop_amount)

			# TODO: Add variable drop amounts
			ore_tilemap.erase_cell(tile)
			
			if chunk_items:
				inventory.add_item(item, drop_amount)
			else:
				call_deferred("drop_item_entity", location, item, drop_amount)
		#tile destroy animation
		if animate:
			var break_location = cave_blocks_tilemap.map_to_local(tile)
			var block_break_anim = block_break_scene.instantiate()
			add_child(block_break_anim)
			block_break_anim.position = break_location
		
		# destroy tile
		cave_blocks_tilemap.erase_cell(tile)

	if chunk_items:
		for item in inventory.get_items():
			var drop_amount := inventory.get_item_amount(item)
			var location = explosion_tiles.pick_random()
			call_deferred("drop_item_entity", location, item, drop_amount, 4 if chunk_items else 10)
	
	StatsManager.add_to_stat(StatsManager.Stat.TILES_BROKEN, explosion_tiles.size())
	
	if rebake:
		for nav_mesh in nav_meshes.get_children():
			var baked_nav_mesh: Array = []
			if nav_mesh is NavigationRegion2D:
				var outline = nav_mesh.get_bounds()
				var bounding_box = outline.grow(100)
				for tile in explosion_tiles:
					if bounding_box.has_point(cave_blocks_tilemap.map_to_local(tile)):
						if not baked_nav_mesh.has(nav_mesh):
							baked_nav_mesh.append(nav_mesh)
							nav_mesh.bake_navigation_polygon()


const ITEM_ENTITY := preload("uid://bkh5wheo7tg4h")

func drop_item_entity(location: Vector2, item: Item, amount: int, max_stacks := 10) -> void:
	if item == null:
		push_warning("Cannot drop null item!")
		return
	if amount < 1:
		push_warning("Cannot drop zero or negative amount")
		return
	
	var chunks: Array[int] = []
	
	@warning_ignore("integer_division")
	var small_piece_size := floori(amount / max_stacks)
	var amount_of_large_pieces = amount % max_stacks
	
	for i in range(max_stacks):
		if i < amount_of_large_pieces:
			chunks.append(small_piece_size + 1)
		else:
			chunks.append(small_piece_size)
			
	for i in range(chunks.size()):
		if chunks[i] > 0:
			var new_entity: ItemEntity = ITEM_ENTITY.instantiate()
			new_entity.item = item
			new_entity.quantity = chunks[i]
			
			add_child(new_entity)
			var offset_vector := Vector2.ONE.rotated(randf() * 2 * PI)
			new_entity.position = location + offset_vector * 4
			new_entity.apply_central_impulse(offset_vector * 100)

func _on_spawn_area_player_detector_player_entered(_player):
	player.health_component.is_invulnerable = true
	player.health_component.heal(player.health_component.maximum_health)
	#handle camera tween
	switch_camera_mode(CameraMode.SPAWN_ROOM_STATIC)
	process_camera()
	restock_player(player)


func restock_player(player):
		# restock player
	for item in restock_inventory.get_items():
		var amount_in_player_inventory: int = player.bomb_inventory_component.inventory.get_item_amount(item)
		var restock_amount := restock_inventory.get_item_amount(item)
		if amount_in_player_inventory < restock_amount:
			var diff := restock_amount - amount_in_player_inventory
			player.bomb_inventory_component.inventory.add_item(item, diff)
			
	player.jetpack.restock()
	$RestockSound.play()

func _on_spawn_area_player_detector_player_exited(_player):
	player.health_component.is_invulnerable = false
	#handle camera tween
	switch_camera_mode(CameraMode.FOLLOWING_PLAYER)
	process_camera()
	#var camera_tweener = get_tree().create_tween()
	restock_player(player)
	#
func _on_player_death():
	switch_camera_mode(CameraMode.FROZEN)
	process_camera()
