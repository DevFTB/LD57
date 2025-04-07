extends Resource
class_name LootTable

@export var entries: Array[LootTableEntry] = []

func generate(slots: int) -> Inventory:
    var inventory: Inventory = Inventory.new()
    var _entries := entries.duplicate()

    for i in range(slots):
        var selected_entry: LootTableEntry
        for en: LootTableEntry in _entries:
            var n := randf()
            
            if n < en.probability:
                selected_entry = en
                break
        
        if selected_entry != null:
            inventory.add_item(selected_entry.item, selected_entry.amount_of_drops.sample())
            _entries.erase(selected_entry)
    
    return inventory

func _to_string() -> String:
   return ",".join(entries.map(func(x: LootTableEntry) -> String: return x.to_string()))
