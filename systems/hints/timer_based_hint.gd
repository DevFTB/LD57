extends Hint

@export var target_timer: Node
@export var wait_time_threshold: float

func are_conditions_satisfied() -> bool:
	return target_timer.time_left < wait_time_threshold
