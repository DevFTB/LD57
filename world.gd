class_name World extends Node2D

const BASE_ZOOM = 1.5
const SPAWN_ZOOM = 1.8
@export var spawn_camera_offset: Vector2 = Vector2(0, -30)

## Everytime the player enters spawn their bomb inventory will have atleast this many of each item
@export var restock_inventory: Inventory

@onready var player: Player = $Player
@onready var cave_blocks_tilemap: TileMapLayer = $Level/CaveBlocks
@onready var ore_tilemap: TileMapLayer = $Level/OreIndicators
@onready var nav_meshes = $Level/NavMeshes
@onready var camera = $MainCamera
@onready var winch = $Winch

@onready var block_break_scene = preload("res://systems/music_sfx/files/sfx/tile/block_break.tscn")

var camera_following_player: bool = false
var initial_camera_location

class ThrowReleasedEventData:
	var position: Vector2
	var impulse: Vector2
	var bomb_type: BombType
	
func _ready() -> void:
	player.throw_released.connect(_spawn_bomb_with_velocity)
	player.health_component.died.connect(_on_player_death)
	initial_camera_location = camera.position
	
func _physics_process(_delta):
	if camera_following_player:
		var camera_tweener = get_tree().create_tween()
		camera_tweener.tween_property(camera, "global_position", player.global_position, 0.3)


func _spawn_bomb_with_velocity(data: ThrowReleasedEventData) -> void:
	var new_bomb := data.bomb_type.bomb_scene.instantiate() as ThrowableBomb
	new_bomb.bomb_type = data.bomb_type
	
	add_child(new_bomb)
	new_bomb.global_position = data.impulse.normalized() * 30 + data.position
	new_bomb.apply_central_impulse(data.impulse)
	
	new_bomb.exploded.connect(_on_bomb_exploded.bind(new_bomb))

func _on_bomb_exploded(bomb: ThrowableBomb) -> void:
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

	for tile in explosion_tiles:
		var has_ore := ore_tilemap.get_cell_source_id(tile) != -1
		# check for drops
		if has_ore:
			var location = ore_tilemap.map_to_local(tile)
			var item: Item = ore_tilemap.get_cell_tile_data(tile).get_custom_data("drop_item")
			
			var drop_amount := 1
			
			if item.id == &"bombpowder":
				StatsManager.add_to_stat(StatsManager.Stat.BOMBPOWDER_MINED, drop_amount)

			if item.id == &"upgradium":
				StatsManager.add_to_stat(StatsManager.Stat.UPGRADIUM_MINED, drop_amount)

			# TODO: Add variable drop amounts
			ore_tilemap.erase_cell(tile)

			call_deferred("drop_ore", location, item, drop_amount)
			
		#tile destroy animation
		var break_location = cave_blocks_tilemap.map_to_local(tile)
		var block_break_anim = block_break_scene.instantiate()
		add_child(block_break_anim)
		block_break_anim.position = break_location
		
		# destroy tile
		cave_blocks_tilemap.erase_cell(tile)

	StatsManager.add_to_stat(StatsManager.Stat.TILES_BROKEN, explosion_tiles.size())
	
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
func drop_ore(location: Vector2, item: Item, amount: int) -> void:
	if item == null:
		push_warning("Cannot drop null item!")
		return
	if amount < 1:
		push_warning("Cannot drop zero or negative amount")
		return

	for i in range(amount):
		var new_entity: ItemEntity = ITEM_ENTITY.instantiate()
		new_entity.item = item
		new_entity.quantity = 1
		
		add_child(new_entity)
		var offset_vector := Vector2.ONE.rotated(randf() * 2 * PI)
		new_entity.position = location + offset_vector * 4
		new_entity.apply_central_impulse(offset_vector * 100)

func _on_spawn_area_player_detector_player_entered(_player):
	player.health_component.is_invulnerable = true
	player.health_component.heal(player.health_component.maximum_health)
	#handle camera tween
	camera_following_player = false
	var camera_tweener = get_tree().create_tween()
	camera_tweener.set_ease(Tween.EASE_IN_OUT)
	camera_tweener.set_trans(Tween.TRANS_CUBIC)
	camera_tweener.tween_property(camera, "zoom", Vector2.ONE * SPAWN_ZOOM, 1)
	camera_tweener.parallel().tween_property(camera, "position", initial_camera_location + spawn_camera_offset, 1)

	# restock player
	for item in restock_inventory.get_items():
		var amount_in_player_inventory := player.bomb_inventory_component.inventory.get_item_amount(item)
		var restock_amount := restock_inventory.get_item_amount(item)
		if amount_in_player_inventory < restock_amount:
			var diff := restock_amount - amount_in_player_inventory
			player.bomb_inventory_component.inventory.add_item(item, diff)
	# TODO: play restock sound.


func _on_spawn_area_player_detector_player_exited(_player):
	player.health_component.is_invulnerable = false
	#handle camera tween
	camera_following_player = true
	var camera_tweener = get_tree().create_tween()
	camera_tweener.set_ease(Tween.EASE_IN)
	camera_tweener.tween_property(camera, "zoom", Vector2.ONE * BASE_ZOOM, 1)
	camera_tweener.parallel().tween_property(camera, "position", initial_camera_location, 1)
	
func _on_player_death():
	camera_following_player = false
