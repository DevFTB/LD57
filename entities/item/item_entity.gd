extends RigidBody2D
class_name ItemEntity

@export var item: Item
@export var quantity: int = 1
var consumed := 0
var pickup_sound_scene = preload("res://systems/music_sfx/files/sfx/ui/pickup_sound.tscn")

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetectorArea2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var combination_area_2d: Area2D = $CombinationArea2D
func _ready() -> void:
	sprite_2d.texture = item.texture
	player_detector.player_entered.connect(_on_player_entered)

	$Timer.wait_time += randf()
	$Timer.timeout.connect(consume, ConnectFlags.CONNECT_DEFERRED)

func get_consumed() -> void:
	if consumed > 0:
		queue_free()

func consume() -> void:
	if not is_queued_for_deletion():
		var other_item_entities := combination_area_2d.get_overlapping_bodies()
		print(other_item_entities.size())
		for item_entity: ItemEntity in other_item_entities:
			if not item_entity.is_queued_for_deletion() and not item_entity == self:
				if item_entity.item == item:
					quantity += item_entity.quantity
					item_entity.queue_free()
					consumed += 1
		
	#prints(name, consumed)

func _on_player_entered(player: Player) -> void:
	if player.can_pickup:
		if item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT):
			player.bomb_inventory_component.inventory.add_item(item, quantity)
		else:
			player.mineral_inventory_component.inventory.add_item(item, quantity)
		var sound = pickup_sound_scene.instantiate()
		get_tree().get_first_node_in_group("world").add_child(sound)
		sound.global_position = global_position
		queue_free()
