extends Node2D

@onready var sprite = $".."

func _process(_delta):
	if sprite.flip_h:
		$BombSpriteLeft.visible = false
		$BombSpriteRight.visible = true
	else:
		$BombSpriteLeft.visible = true
		$BombSpriteRight.visible = false
