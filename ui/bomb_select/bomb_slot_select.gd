extends Control
class_name BombSlotSelect

@export var slot_number := 1
@export var bomb_item: Item

var bomb_type: BombType:
	get:
		return bomb_item.get_data_component(Item.DataCompontents.BOMB_DATA_COMPONENT) if bomb_item else null

@onready var texture_rect: TextureRect = %TextureRect
@onready var slot_label: Label = %SlotLabel
@onready var amount_label: Label = %AmountLabel
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var player_bomb_inventory: Inventory = player.bomb_inventory_component.inventory
@onready var restock_inventory: Inventory = get_tree().get_first_node_in_group("world").restock_inventory

func _ready() -> void:
	slot_label.label_settings = slot_label.label_settings.duplicate()
	update()
	
	player_bomb_inventory.item_modified.connect(update.unbind(2))
	restock_inventory.item_modified.connect(update.unbind(2))
	player.selected_bomb_changed.connect(update.unbind(1))

func update() -> void:
	if bomb_item != null:
		show()
		var amount_in_player_inventory := player_bomb_inventory.get_item_amount(bomb_item)
		var amount_in_restock_inventory := restock_inventory.get_item_amount(bomb_item)

		texture_rect.texture = bomb_item.texture
		slot_label.text = str(slot_number)
		amount_label.text = "∞" if not bomb_type.is_perishable else str(amount_in_player_inventory) + "/" + str(amount_in_restock_inventory)
		
		texture_rect.modulate = Color(0.4, 0.4, 0.4, 1.0) if amount_in_player_inventory < 1 else Color.WHITE
		slot_label.label_settings.font_color = Color.ORANGE if player.selected_bomb_item == bomb_item else Color.WHITE
	else:
		texture_rect.texture = null
		slot_label.text = ""
		amount_label.text = ""
