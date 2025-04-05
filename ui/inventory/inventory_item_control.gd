extends Control
class_name InventoryItemControl

@export var item: Item

@export var texture_rect: TextureRect
@export var amount_label: Label

func set_item(new_item: Item, amount: int) -> void:
	item = new_item

	texture_rect.texture = item.texture
	amount_label.text = str(amount)
