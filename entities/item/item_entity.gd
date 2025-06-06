extends RigidBody2D
class_name ItemEntity

const MAGNET_STRENGTH = 500
@export var scale_curve: Curve
@export var item: Item
@export var quantity: int = 1
var consumed := 0
var pickup_sound_scene = preload("res://systems/music_sfx/files/sfx/ui/pickup_sound.tscn")

@onready var player_detector: PlayerDetectorArea2D = $PlayerDetectorArea2D
@onready var sprite_2d: Sprite2D = $Node2D/Sprite2D
@onready var combination_area_2d: Area2D = $CombinationArea2D
@onready var timer = $Timer
@onready var original_sprite_scale := sprite_2d.scale
@onready var node_2d: Node2D = $Node2D

var player: Player


func _ready() -> void:
	sprite_2d.texture = item.texture
	calc_scale() 
	player_detector.player_entered.connect(_on_player_entered)
	player = get_tree().get_first_node_in_group("player")
	if timer:
		timer.wait_time += randf()
		timer.timeout.connect(consume, ConnectFlags.CONNECT_DEFERRED)

func get_consumed() -> void:
	if consumed > 0:
		queue_free()

var tween : Tween
func calc_scale() -> void:
	if tween:
		tween.kill()
	var target_scale := Vector2.ONE * scale_curve.sample_baked(min(quantity, scale_curve.max_domain))
	tween = create_tween()
	tween.tween_property(node_2d, "scale", target_scale, 0.4).set_trans(Tween.TRANS_BOUNCE)
	
func consume() -> void:
	if not is_queued_for_deletion():
		var other_item_entities := combination_area_2d.get_overlapping_bodies()
		for item_entity: ItemEntity in other_item_entities:
			if not item_entity.is_queued_for_deletion() and not item_entity == self:
				if item_entity.item == item:
					quantity += item_entity.quantity
					calc_scale() 
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

func _physics_process(delta: float) -> void:
	if player:
		var player_vector = player.global_position - global_position
		var magnet_range = player.get_magnet_range()
		var distance = player_vector.length()
		if distance < player.get_magnet_range():
			apply_central_force(player_vector * MAGNET_STRENGTH * player.magnet_strength_multiplier / distance)
