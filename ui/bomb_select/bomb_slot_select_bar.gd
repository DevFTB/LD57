extends Control

@export var inventory_component: InventoryComponent
var select_slots: Array[BombSlotSelect] = []

func _ready() -> void:
	select_slots.assign(get_children())
	inventory_component.inventory.item_modified.connect(_on_item_modified.unbind(2))
	_on_item_modified()
	
func _on_item_modified() -> void:
	var inventory := inventory_component.inventory
	var unique_items = inventory.get_items()
	for i in range(unique_items.size()):
		select_slots[i].bomb_item = unique_items[i]
		select_slots[i].update()
