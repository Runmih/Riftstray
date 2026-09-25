extends Resource

@export var unit_id: StringName

func matches(info: Dictionary) -> bool:
	return info.units.has(unit_id) and not info.units[unit_id].alive

func progress(info: Dictionary) -> Dictionary:
	var unit: Dictionary = info.units.get(unit_id, {})
	return {"kind": &"unit_dead", "unit_id": unit_id, "name": unit.get("name", String(unit_id)), "met": matches(info)}
