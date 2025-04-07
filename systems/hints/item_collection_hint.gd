extends Hint

@export var target_item: Item
@export var required_quantity: int = 1
@export var inventory_component: InventoryComponent

var max_tracked := 0

func _ready() -> void:
	super._ready()
	inventory_component.inventory.item_modified.connect(_on_item_modified)

func _on_item_modified(item: Item, amount: int) -> void:
	if item == target_item:
		max_tracked = maxi(amount, max_tracked)

func are_conditions_satisfied() -> bool:
	return max_tracked >= required_quantity