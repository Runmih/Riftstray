extends Resource

@export var faction: StringName = &"enemy"

func matches(info: Dictionary) -> bool:
	var status: Dictionary = progress(info)
	return status.found and status.remaining == 0

func progress(info: Dictionary) -> Dictionary:
	var remaining: int = 0
	var found: bool = false
	for unit: Dictionary in info.units.values():
		if unit.faction == faction:
			found = true
			if unit.alive and not unit.escaped:
				remaining += 1
	return {"kind": &"faction_defeated", "faction": faction, "remaining": remaining, "found": found}