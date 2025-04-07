extends Hint

@export var trigger_depth: float = 5.0

func are_conditions_satisfied() -> bool:
    var correct_depth := StatsManager.get_stat(StatsManager.Stat.MAX_DEPTH) > trigger_depth
    return correct_depth