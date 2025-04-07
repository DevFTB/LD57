extends Label

@export var stat: StatsManager.Stat
@export var title: String

func _ready() -> void:
    _on_stat_updated(stat, 0)
    StatsManager.connect_to_updated(_on_stat_updated)
    
func _on_stat_updated(updated_stat: StatsManager.Stat, new_value: int) -> void:
    if self.stat == updated_stat:
        text = "%s: %d" % [title, new_value]
