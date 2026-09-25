extends RefCounted

var remaining: Dictionary = {}

func reset(units: Array, faction: StringName) -> void:
	remaining.clear()
	for unit in units:
		if unit.current_hp > 0 and not unit.escaped and unit.template.faction == faction:
			remaining[unit.id] = 1 + unit.extra_actions

func available(unit: RefCounted) -> bool:
	return unit.current_hp > 0 and not unit.escaped and not unit.stunned and int(remaining.get(unit.id, 0)) > 0

func grant(unit_id: StringName, amount: int) -> void:
	remaining[unit_id] = maxi(0, int(remaining.get(unit_id, 0)) + amount)

func spend(unit: RefCounted) -> bool:
	if not available(unit):
		return false
	remaining[unit.id] -= 1
	return true

func finish(unit_id: StringName) -> void:
	remaining[unit_id] = 0

