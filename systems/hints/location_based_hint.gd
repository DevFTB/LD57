extends Hint

@export var area_2d: Area2D
@export var player: Player

func are_conditions_satisfied() -> bool:
    return area_2d.get_overlapping_bodies().has(player)