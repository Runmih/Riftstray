extends RefCounted

var _rules: Array = []
var _group: RefCounted
var _turns: RefCounted

func configure(rules: Array, group: RefCounted, turns: RefCounted) -> void:
	_rules = rules
	_group = group
	_turns = turns

func on_unit_moved(unit: RefCounted) -> void:
	if unit.current_hp <= 0 or unit.escaped:
		return
	for rule: Dictionary in _rules:
		if rule.has("tag") and not unit.template.tags.has(StringName(rule.tag)):
			continue
		if rule.has("unit_ids") and not rule.unit_ids.has(String(unit.id)):
			continue
		for cell: Array in rule.cells:
			if unit.cell != Vector2i(int(cell[0]), int(cell[1])):
				continue
			unit.escaped = true
			_turns.actions.finish(unit.id)
			_turns.movement.finish(unit.id)
			_group.sync_occupancy()
			return

func marker_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for rule: Dictionary in _rules:
		for cell: Array in rule.cells:
			var position := Vector2i(int(cell[0]), int(cell[1]))
			if not result.has(position):
				result.append(position)
	return result