extends Resource
class_name BombType

@export var id: StringName
@export var bomb_icon: Texture2D
@export var bomb_scene: PackedScene = preload("res://entities/throwables/bomb/throwable_bomb_entity.tscn")

@export_subgroup("Gameplay")
@export var hardness: float = 1
@export var is_perishable: bool = false
@export var is_sticky: bool = false
@export var explosion_radius: int = 2
@export var entity_damage: int = 50
