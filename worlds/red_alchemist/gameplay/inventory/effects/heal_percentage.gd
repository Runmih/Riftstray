extends Resource

@export_range(0.01, 1.0) var healing_ratio: float = 0.35

func healing_amount(unit: RefCounted) -> int:
	var maximum: int = maxi(1, int(unit.attributes.get(&"max_hp", 1)))
	return maxi(1, ceili(maximum * clampf(healing_ratio, 0.01, 1.0)))

func apply(unit: RefCounted) -> void:
	if unit.current_hp <= 0:
		return
	var maximum: int = maxi(1, int(unit.attributes.get(&"max_hp", 1)))
	unit.current_hp = mini(maximum, unit.current_hp + healing_amount(unit))

func description_for(unit: RefCounted) -> String:
	return "Heal: %d%% max HP (%d HP)" % [roundi(healing_ratio * 100.0), healing_amount(unit)]