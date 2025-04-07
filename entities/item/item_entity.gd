extends RigidBody2D
class_name ItemEntity

@export var item: Item
@export var quantity: int = 1

var pickup_sound_scene = preload("res://systems/music_sfx/files/sfx/ui/pickup_sound.tscn")

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetectorArea2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite_2d.texture = item.texture
	player_detector.player_entered.connect(_on_player_entered)


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
