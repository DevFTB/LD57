extends LevelGen

func _ready() -> void:
	HARDNESS_THRESHOLDS.sort()
	# set globalscope seed
	seed(random_seed)

	resource_noise[Resources.UPGRADIUM] = upgradium_ore_noise
	resource_noise[Resources.BOMB_POWDER] = bomb_powder_ore_noise
	
	generate_cave_blocks(cave_noise, hardness_noise, resource_noise, -100, 100, -100, 100)

func _process(delta: float) -> void:
	pass
