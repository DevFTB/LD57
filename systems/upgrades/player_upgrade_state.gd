extends Resource
class_name PlayerUpgradeState

var upgrade_tier_levels: Dictionary[Upgrade, Array]

func get_tier_level(upgrade: Upgrade, tier) -> int:
	var levels = upgrade_tier_levels.get_or_add(upgrade, Array())
	if levels.is_empty():
		levels.resize(upgrade.num_tiers)
		levels.fill(0)
	return levels[tier]

func get_tier_value(upgrade: Upgrade, tier) -> Variant:
	return upgrade.tier_value_map[tier] * get_tier_level(upgrade, tier)

func increment_upgrade_tier_level(upgrade: Upgrade, tier) -> void:
	var current_tier := get_tier_level(upgrade, tier)
	upgrade_tier_levels.get(upgrade)[tier] += 1
	emit_changed()
	
func get_total_value(upgrade: Upgrade) -> Variant:
	var sum = 0
	for tier in range(upgrade.num_tiers):
		sum += get_tier_value(upgrade, tier)
	return sum
		
