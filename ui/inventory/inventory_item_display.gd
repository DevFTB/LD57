extends Control

@export var inventory: Inventory
@export var item: Item

@export var texture_rect: TextureRect
@export var label: Label

func _ready() -> void:
    if inventory.has_item(item):
        update(item.texture, inventory.get_item_amount(item))
    
    inventory.item_modified.connect(_on_item_modified.unbind(2))
    
func _on_item_modified() -> void:
    update(item.texture, inventory.get_item_amount(item))

func update(texture: Texture2D, amount: int) -> void:
    texture_rect.texture = texture
    label.text = str(amount)