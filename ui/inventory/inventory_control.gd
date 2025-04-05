extends Control
class_name InventoryControl

@export var inventory: Inventory
@export var item_control: PackedScene
@export var control_parent: Control

var _item_controls := {}

func _ready() -> void:
	set_inventory(inventory)

func set_inventory(new_inventory: Inventory) -> void:
	if inventory.item_modified.is_connected(_on_item_modified):
		inventory.item_modified.disconnect(_on_item_modified)
	
	inventory = new_inventory
	inventory.item_modified.connect(_on_item_modified)
	
	_build()

func _build() -> void:
	for control: InventoryItemControl in _item_controls.values():
		control.queue_free()
	
	_item_controls.clear()
	
	for item in inventory.get_items():
		_create_item_control(item, inventory.get_item_amount(item))

func _on_item_modified(item: Item, new_amount: int) -> void:
	var control: InventoryItemControl = _item_controls.get(item)
	
	if not control:
		_create_item_control(item, new_amount)
	else:
		control.set_item(item, new_amount)

func _create_item_control(item: Item, amount: int) -> void:
	var new_control: InventoryItemControl = item_control.instantiate()
	new_control.set_item(item, amount)
	_item_controls[item] = new_control
	
	control_parent.add_child(new_control)
