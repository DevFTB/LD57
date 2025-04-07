extends RigidBody2D
class_name ItemEntity

@export var item: Item
@export var quantity: int = 1

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetectorArea2D
@onready var sprite_2d: Sprite2D = $Sprite2D

const MAGNET_STRENGTH = 1000
var player : Player

func _ready() -> void:
	sprite_2d.texture = item.texture
	player_detector.player_entered.connect(_on_player_entered)
	player = get_tree().get_first_node_in_group("player")



func _on_player_entered(player: Player) -> void:
	if player.can_pickup:
		player.mineral_inventory_component.inventory.add_item(item, quantity)
		queue_free()

func _process(delta:float) -> void:
	var player_vector = player.global_position - global_position
	var magnet_range = player.get_magnet_range()
	var distance = player_vector.length()
	if distance < player.get_magnet_range():
		apply_central_force(player_vector * MAGNET_STRENGTH * player.magnet_strength_multiplier / distance)
		
	
