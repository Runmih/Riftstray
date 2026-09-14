extends Resource

@export var unit_id: StringName
@export var destination: Vector2i

func matches(info: Dictionary) -> bool:
	if not info.units.has(unit_id):
		return false
	var unit: Dictionary = info.units[unit_id]
	return unit.alive and (unit.escaped or unit.cell == destination)

func describe(info: Dictionary) -> String:
	var unit: Dictionary = info.units.get(unit_id, {})
	return "%s reaches (%d, %d)" % [unit.get("name", String(unit_id).capitalize()), destination.x, destination.y]
