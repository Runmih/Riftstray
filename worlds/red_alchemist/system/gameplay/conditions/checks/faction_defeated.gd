extends Resource

@export var faction: StringName = &"enemy"

func matches(info: Dictionary) -> bool:
	var found: bool = false
	for unit: Dictionary in info.units.values():
		if unit.faction == faction:
			found = true
			if unit.alive and not unit.escaped:
				return false
	return found

func describe(info: Dictionary) -> String:
	var remaining: int = 0
	for unit: Dictionary in info.units.values():
		if unit.faction == faction and unit.alive and not unit.escaped:
			remaining += 1
	return "Defeat %s units: %d remaining" % [String(faction).capitalize(), remaining]
