extends Resource

@export var unit_id: StringName

func matches(info: Dictionary) -> bool:
	return info.units.has(unit_id) and not info.units[unit_id].alive

func describe(info: Dictionary) -> String:
	var unit: Dictionary = info.units.get(unit_id, {})
	return "%s falls" % unit.get("name", String(unit_id).capitalize())
