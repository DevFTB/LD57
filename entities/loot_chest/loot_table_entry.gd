extends Resource
class_name LootTableEntry

@export var item: Item
@export var probability: float
@export var amount_of_drops: RandomInt

func _to_string() -> String:
    return "%s (%d - %d) with prob. %f" % [item.display_name, amount_of_drops.min_value, amount_of_drops.max_value, probability]