extends Sprite2D

@export var target_size: Vector2 = Vector2(32, 32)

func _ready() -> void:
    texture_changed.connect(resize)
    
func resize() -> void:
    var rx = target_size.x / texture.get_size().x
    var ry = target_size.y / texture.get_size().y
    scale = Vector2(rx, ry)
