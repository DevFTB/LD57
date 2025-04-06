extends RigidBody2D
class_name ItemEntity

@export var item: Item
@export var quantity: int = 1

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetectorArea2D
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite_2d.texture = item.texture
	player_detector.player_entered.connect(_on_player_entered)

func _on_player_entered(player: Player) -> void:
	player.mineral_inventory_component.inventory.add_item(item, quantity)
	queue_free()
