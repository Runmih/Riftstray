extends RefCounted

var remaining: Dictionary = {}

func reset(units: Array, faction: StringName) -> void:
	remaining.clear()
	for unit in units:
		if unit.current_hp > 0 and not unit.escaped and unit.template.faction == faction:
			remaining[unit.id] = unit.get_movement() * (1 + unit.extra_moves)

func grant(unit_id: StringName, amount: int) -> void:
	remaining[unit_id] = maxi(0, int(remaining.get(unit_id, 0)) + amount)

func available(unit: RefCounted) -> bool:
	return unit.current_hp > 0 and not unit.escaped and not unit.stunned and int(remaining.get(unit.id, 0)) > 0

func reachable(unit: RefCounted, group: RefCounted) -> Dictionary:
	if not available(unit):
		return {}
	group.sync_occupancy()
	return group.grid.reachable_cells(unit.cell, mini(unit.get_movement(), int(remaining.get(unit.id, 0))), unit.template.movement_profile)

func move(unit: RefCounted, destination: Vector2i, group: RefCounted) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not available(unit):
		return empty
	group.sync_occupancy()
	var path: Array[Vector2i] = group.grid.find_path(unit.cell, destination, unit.template.movement_profile, mini(unit.get_movement(), int(remaining.get(unit.id, 0))))
	var cost: int = group.grid.path_cost(path, unit.template.movement_profile)
	if path.size() < 2 or cost <= 0:
		return empty
	remaining[unit.id] -= mini(unit.get_movement(), int(remaining.get(unit.id, 0)))
	unit.cell = destination
	group.sync_occupancy()
	return path

func finish(unit_id: StringName) -> void:
	remaining[unit_id] = 0

