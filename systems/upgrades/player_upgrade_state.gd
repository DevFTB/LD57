extends Resource
class_name PlayerUpgradeState

var upgrade_tiers: Dictionary[Upgrade, int]

func get_tier(upgrade: Upgrade) -> int:
	return upgrade_tiers.get(upgrade, 0)

func get_value(upgrade: Upgrade) -> Variant:
	return upgrade.tier_value_map[get_tier(upgrade)]

func increment_upgrade_tier(upgrade: Upgrade) -> void:
	var current_tier := get_tier(upgrade)
	upgrade.upgraded.emit()
	if upgrade.num_tiers > current_tier + 1:
		upgrade_tiers.set(upgrade, current_tier + 1)
		
		emit_changed()
