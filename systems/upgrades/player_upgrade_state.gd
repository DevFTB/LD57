extends Resource
class_name PlayerUpgradeState

signal upgraded(upgrade: Upgrade, tier)

enum UpgradeType {
	BOMB_RADIUS,
	BOMB_HARDNESS,
	GRAPPLE_RANGE,
	HEALTH,
	JETPACK,
	MAGNET,
	JETPACK_FUEL,
	INVULNERABILITY,
	MULTIBOMB,
	MULTIBOMB_AMOUNT,
	BLAST_RESISTANCE,
	STICKY_RESTOCK_AMOUNT,
	IMPACT_RESTOCK_AMOUNT,
	SHRAPNEL_RESTOCK_AMOUNT,
	NUKE_RESTOCK_AMOUNT,
	GRAPPLE_COOLDOWN
}

@export var upgrades : Dictionary[UpgradeType, Upgrade]

var upgrade_tier_levels: Dictionary[Upgrade, Array]

func get_tier_level(upgrade: Upgrade, tier) -> int:
	var levels = upgrade_tier_levels.get_or_add(upgrade, Array())
	if levels.is_empty():
		levels.resize(upgrade.num_tiers)
		levels.fill(0)
	return levels[tier]

func get_tier_value(upgrade: Upgrade, tier) -> Variant:
	if upgrade.mult: return ((upgrade.tier_values[tier] - 1) * get_tier_level(upgrade, tier)) + 1
	return upgrade.tier_values[tier] * get_tier_level(upgrade, tier)

func increment_upgrade_tier_level(upgrade: Upgrade, tier) -> void:
	var current_tier := get_tier_level(upgrade, tier)
	upgrade_tier_levels.get(upgrade)[tier] += 1
	emit_changed()
	upgraded.emit(upgrade, tier)

func get_total_value(upgrade: Upgrade) -> Variant:
	var cumulative = 0
	if upgrade.mult: cumulative = 1
	for tier in range(upgrade.num_tiers):
		if upgrade.mult: cumulative = cumulative * get_tier_value(upgrade, tier)
		else: cumulative += get_tier_value(upgrade, tier)
	return cumulative
		
