extends Resource

@export var unit_id: StringName
@export var destination: Vector2i

func matches(info: Dictionary) -> bool:
	if not info.units.has(unit_id):
		return false
	var unit: Dictionary = info.units[unit_id]
	return unit.alive and (unit.escaped or unit.cell == destination)

func progress(info: Dictionary) -> Dictionary:
	var unit: Dictionary = info.units.get(unit_id, {})
	return {"kind": &"reach_destination", "unit_id": unit_id, "name": unit.get("name", String(unit_id)), "met": matches(info), "destination": destination}
