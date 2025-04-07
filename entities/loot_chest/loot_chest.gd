extends StaticBody2D

@export var loot_table: LootTable
@export var slots := 3

@onready var inventory := loot_table.generate(slots)

@onready var health_component: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	health_component.died.connect(die)
	print(loot_table)

const ITEM_ENTITY = preload("res://entities/item/item_entity.tscn")
func die() -> void:
	# play sounds
	# spawn item entities
	for item in inventory.get_items():
		for i in range(inventory.get_item_amount(item)):
			var dropped_item = ITEM_ENTITY.instantiate()
			dropped_item.item = item
			dropped_item.quantity = 1
			inventory.remove_item(item, dropped_item.quantity)
			get_tree().get_first_node_in_group("world").call_deferred("add_child", dropped_item)
			dropped_item.global_position = self.global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			dropped_item.linear_velocity = Vector2(randf_range(-300, 300), randf_range(-300, 300))

	# play death animation
	animation_player.play("die")
