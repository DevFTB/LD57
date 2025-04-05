extends Resource
class_name Inventory

signal item_modified(item: Item, new_amount: int)

## If greater than -1, items may not be added if this amount of items (not unique) exist in the inventory
@export var maximum_size: int = -1

## The starting inventory which will be added on ready. Expects a Item as the key, and an integer as the amount.
@export var starting_inventory: Dictionary:
	set(value):
		starting_inventory = value
		for item in starting_inventory:
			add_item(item, starting_inventory.get(item, 0))

var _inventory := {}
var _current_size := 0

## Tries to add a certain amount of an item to the inventory. Will only add if entire amount can be added, otherwise will fail with warning.
func add_item(item: Item, amount: int) -> void:
	if amount < 0:
		push_warning("Cannot add negative amount")
		return
		
	if maximum_size > -1 and _current_size + amount > maximum_size:
		push_warning("Cannot add %d amount of %s, exceeds maximum size %d" % [amount, item.id, maximum_size])
		return
	
	var sum: int = _inventory.get(item, 0) + amount
	_inventory[item] = sum
	_current_size += amount
	
	item_modified.emit(item, sum)
	
## Tries to remove a certain amount of an item to the inventory. Will only add if entire amount can be removed, otherwise will fail with warning.
func remove_item(item: Item, amount: int) -> void:
	if amount < 0:
		push_warning("Cannot remove negative amount")
		return
	
	var current_amount: int = _inventory.get_or_add(item, 0)
	
	if not amount <= current_amount:
		push_warning("Inventory does not contain at least %d amount of %s." % [amount, item.id])
		return
	
	_inventory[item] -= amount
	_current_size -= amount
	
	item_modified.emit(item, _inventory.get(item))

## Gets the amount of the item in the inventory
func get_item_amount(item: Item) -> int:
	return _inventory.get_or_add(item, 0)

## Checks if the there is an amount of an item in the inventory.
func has_item(item: Item, amount: int = 1) -> bool:
	return _inventory.get_or_add(item, 0) >= amount

## Gets the items in the inventory that have a non-zero amount.
func get_items() -> Array[Item]:
	var non_zero_items: Array[Item] = []
	for key in _inventory:
		if _inventory.get(key) > 0:
			non_zero_items.append(key)
	
	return non_zero_items

## Returns the amount of items total stored in the inventory.
func size() -> int:
	return _current_size

## Returns how many unique items of non-zero amount are stored in the inventory.
func unique_size() -> int:
	var non_zero_count := 0
	for key in _inventory:
		if _inventory.get(key) > 0:
			non_zero_count += 1
	
	return non_zero_count

func has_maximum() -> bool:
	return maximum_size != -1

func can_fit(amount: int) -> bool:
	if has_maximum():
		return maximum_size - size() >= amount
	else:
		return true

func _init(p_maximum_size: int = -1, p_starting_inventory: Dictionary = {}) -> void:
	maximum_size = p_maximum_size
	starting_inventory = p_starting_inventory
