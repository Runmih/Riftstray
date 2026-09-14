extends Resource

@export var tag: StringName = &"citizen"
@export_enum("alive", "dead", "escaped", "remaining") var state: String = "dead"
@export_enum(">=", "<=", "==") var comparison: String = ">="
@export var threshold: int = 4
@export var counter_name: StringName

func count(info: Dictionary) -> int:
	var count: int = 0
	if not counter_name.is_empty():
		count = int(info.counters.get(counter_name, 0))
	else:
		for unit: Dictionary in info.units.values():
			if not unit.tags.has(tag):
				continue
			if (state == "alive" and unit.alive) or (state == "dead" and not unit.alive) or (state == "escaped" and unit.escaped) or (state == "remaining" and unit.alive and not unit.escaped):
				count += 1
	return count

func matches(info: Dictionary) -> bool:
	var current_count: int = count(info)
	match comparison:
		">=": return current_count >= threshold
		"<=": return current_count <= threshold
	return current_count == threshold

func describe(info: Dictionary) -> String:
	var subject: String = String(counter_name).capitalize() if not counter_name.is_empty() else "%s %s" % [String(tag).capitalize(), state]
	var requirement: String = str(threshold)
	if comparison == ">=":
		requirement = "at least " + requirement
	elif comparison == "<=":
		requirement = "at most " + requirement
	return "%s: %d (need %s)" % [subject, count(info), requirement]

