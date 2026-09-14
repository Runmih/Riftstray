extends RefCounted

func capture(units: Array, counters: Dictionary = {}) -> Dictionary:
	var states: Dictionary = {}
	for unit in units:
		states[unit.id] = {"name": unit.template.display_name, "alive": unit.current_hp > 0, "escaped": unit.escaped, "cell": unit.cell, "faction": unit.template.faction, "tags": unit.template.tags.duplicate()}
	return {"units": states, "counters": counters.duplicate()}

