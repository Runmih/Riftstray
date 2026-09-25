extends RefCounted

func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func in_range(origin: Vector2i, target: Vector2i, attack: Resource) -> bool:
	var span: int = distance(origin, target)
	return span >= attack.minimum_range and span <= attack.maximum_range

func collect(attacker: RefCounted, center: Vector2i, units: Array, attack: Resource, hostile_factions: Array[StringName]) -> Array:
	var result: Array = []
	if not in_range(attacker.cell, center, attack):
		return result
	for unit in units:
		if unit == attacker or unit.current_hp <= 0 or unit.escaped or not hostile_factions.has(unit.template.faction):
			continue
		if distance(center, unit.cell) <= attack.area_radius and not result.has(unit):
			result.append(unit)
	result.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return result

