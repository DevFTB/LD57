extends TextureRect

@export var boom_level_textures: Dictionary[int, Texture2D]

func _ready() -> void:
<<<<<<< Updated upstream
    _on_stat_updated()
=======
>>>>>>> Stashed changes
    StatsManager.stat_updated.connect(_on_stat_updated.unbind(2))
    
func _on_stat_updated() -> void:
    texture = boom_level_textures.get(StatsManager.get_boom_level(), null)
