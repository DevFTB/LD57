extends Resource
class_name RandomInt

@export var min_value: int = 1
@export var max_value: int = 1

func sample() -> int:
    return randi_range(min_value, max_value)