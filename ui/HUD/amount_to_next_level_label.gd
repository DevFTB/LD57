extends Label

func _ready() -> void:
    _on_stat_updated()
    StatsManager.stat_updated.connect(_on_stat_updated.unbind(2))
    
func _on_stat_updated() -> void:
    var boom_level := StatsManager.get_boom_level()
    if boom_level < StatsManager.BOOM_LEVELS.size():
        var diff: int = StatsManager.BOOM_LEVELS[boom_level] - StatsManager.get_stat(StatsManager.Stat.BOMBPOWDER_OFFERED)
        text = str(diff)
