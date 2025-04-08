extends Control

@export var inventory_component: InventoryComponent
var select_slots: Array[BombSlotSelect] = []

var slot_map: Array[Item]

func _ready() -> void:
	select_slots.assign(get_children())
	inventory_component.inventory.item_modified.connect(_on_item_modified.unbind(2))
	_on_item_modified()
	
func _on_item_modified() -> void:
	var inventory := inventory_component.inventory
	var unique_items = inventory.get_items()

	for ui in unique_items:
		if not slot_map.has(ui):
			var index = slot_map.size()
			slot_map.append(ui)

			select_slots[index].bomb_item = ui
			select_slots[index].update()
