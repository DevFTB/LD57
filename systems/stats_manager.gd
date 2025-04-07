extends Node

signal stat_updated(stat: Stat, new_value: int)

enum Stat {
	BOMBS_THROWN,
	TILES_BROKEN,
	ENEMIES_KILLED,
	BOMBPOWDER_OFFERED,
	MAX_DEPTH,
	DEATH_COUNT,
	BOMBPOWDER_MINED,
	UPGRADIUM_MINED,
}

const BOOM_LEVELS = [50, 500, 2500]


var dict: Dictionary[int, int] = {}

func connect_to_updated(callable: Callable) -> void:
	stat_updated.connect(callable)

func add_to_stat(stat: Stat, amount: int) -> void:
	var previous: int = dict.get_or_add(stat, 0)
	dict.set(stat, previous + amount)
	stat_updated.emit(stat, dict.get(stat))
	
func surpass_stat(stat: Stat, value: int) -> void:
	var old: int = dict.get_or_add(stat, 0)
	
	if old < value:
		dict.set(stat, value)
		stat_updated.emit(stat, dict.get(stat))

func get_stat(stat: Stat) -> int:
	return dict.get_or_add(stat, 0)

func get_boom_level() -> int:
	var boom_level := BOOM_LEVELS.find_custom(func(lvl: int) -> bool: return get_stat(Stat.BOMBPOWDER_OFFERED) < lvl)
	
	if boom_level == -1:
		return 3
	else:
		return boom_level
