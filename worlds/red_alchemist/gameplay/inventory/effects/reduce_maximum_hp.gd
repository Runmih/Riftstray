extends Resource

@export_range(0.01, 1.0) var remaining_ratio: float = 0.75

func resulting_maximum(unit: RefCounted) -> int:
	return maxi(1, floori(int(unit.attributes.get(&"max_hp", 1)) * clampf(remaining_ratio, 0.01, 1.0)))

func apply(unit: RefCounted) -> void:
	var before: int = int(unit.attributes.get(&"max_hp", 1))
	var after: int = resulting_maximum(unit)
	unit.permanent_hp_loss += before - after
	unit.attributes[&"max_hp"] = after
	unit.current_hp = mini(unit.current_hp, after)

func description_for(unit: RefCounted) -> String:
	return "Max HP: %d → %d · Permanent" % [int(unit.attributes.get(&"max_hp", 1)), resulting_maximum(unit)]