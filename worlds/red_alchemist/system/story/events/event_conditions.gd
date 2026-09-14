extends RefCounted

func matches_all(conditions: Array, session: RefCounted) -> bool:
	for condition: Dictionary in conditions:
		if not matches(condition, session):
			return false
	return true

func matches(condition: Dictionary, session: RefCounted) -> bool:
	match String(condition.get("type", "")):
		"item_used":
			var unit: RefCounted = session.group.get_npc(StringName(condition.unit))
			var key := StringName("item_used/%s/%s" % [condition.unit, condition.item])
			return int(session.counters.get(key, 0)) > 0 or (unit != null and unit.consumed_unique_items.has(StringName(condition.item)))
		"tag_position":
			for unit in session.group.npcs:
				if unit.current_hp <= 0 or not unit.template.tags.has(StringName(condition.tag)):
					continue
				var position: int = unit.cell.x if String(condition.axis) == "x" else unit.cell.y
				if position >= int(condition.minimum):
					return true
		"counter":
			return int(session.counters.get(StringName(condition.key), 0)) >= int(condition.get("minimum", 1))
	return false
