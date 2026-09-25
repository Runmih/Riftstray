extends RefCounted

func format_progress(progress: Dictionary) -> String:
	var lines := PackedStringArray()
	for key: String in ["win", "defeat"]:
		var group: Dictionary = progress.get(key, {})
		var descriptions := PackedStringArray()
		for check: Dictionary in group.get("checks", []):
			descriptions.append(_describe(check))
		if not descriptions.is_empty():
			var title: String = "Victory" if key == "win" else "Defeat"
			lines.append(title + " — " + ("All: " if group.require_all else "Any: ") + " · ".join(descriptions))
	return "\n".join(lines)

func _describe(value: Dictionary) -> String:
	match value.kind:
		&"count":
			var subject: String = String(value.counter).capitalize() if not String(value.counter).is_empty() else "%s %s" % [String(value.tag).capitalize(), value.state]
			var requirement: String = str(value.threshold)
			if value.comparison == ">=":
				requirement = "at least " + requirement
			elif value.comparison == "<=":
				requirement = "at most " + requirement
			return "%s: %d (need %s)" % [subject, value.current, requirement]
		&"unit_dead":
			return "%s falls" % value.name
		&"reach_destination":
			return "%s reaches (%d, %d)" % [value.name, value.destination.x, value.destination.y]
		&"faction_defeated":
			return "Defeat %s units: %d remaining" % [String(value.faction).capitalize(), value.remaining]
	return ""
func format_group(group: Dictionary) -> String:
	var lines := PackedStringArray()
	for value: Dictionary in group.get("checks", []):
		if value.kind == &"count" and String(value.counter).is_empty():
			var people: String = "civilians" if String(value.tag) == "citizen" else String(value.tag)
			if value.state == "remaining" and int(value.threshold) == 0:
				lines.append("Get all surviving %s to the exit.\n%d still on the map." % [people, value.current])
			elif value.state == "escaped" and value.comparison == ">=":
				lines.append("At least %d must escape. Saved: %d." % [value.threshold, value.current])
			elif value.state == "dead" and value.comparison == ">=":
				lines.append("%d %s die. Lost: %d/%d." % [value.threshold, people, value.current, value.threshold])
			else:
				lines.append(_describe(value))
		elif value.kind == &"unit_dead":
			lines.append("%s dies." % value.name)
		else:
			lines.append(_describe(value))
	return ("\n" if group.get("require_all", true) else "\nOR\n").join(lines)