extends RefCounted

const Conditions = preload("res://worlds/red_alchemist/system/story/events/event_conditions.gd")
const Runner = preload("res://worlds/red_alchemist/system/story/scene_runner.gd")
var _session: WeakRef
var _data: Dictionary = {}
var _conditions := Conditions.new()
var _runner := Runner.new()
var active: bool = false

func configure(data: Dictionary, session: RefCounted) -> void:
	_data = data
	_session = weakref(session)
	session.action_permission = allows
	session.turns.action_permission = allows

func record_item_use(unit_id: StringName, item_id: StringName) -> void:
	var session: RefCounted = _session.get_ref()
	var key := StringName("item_used/%s/%s" % [unit_id, item_id])
	session.counters[key] = int(session.counters.get(key, 0)) + 1

func allows(action: StringName, unit_id: StringName = &"", item_id: StringName = &"") -> bool:
	return _restriction(action, unit_id, item_id).is_empty()

func reminder(action: StringName, unit_id: StringName = &"", item_id: StringName = &"") -> String:
	return String(_restriction(action, unit_id, item_id).get("reminder", ""))

func _restriction(action: StringName, unit_id: StringName, item_id: StringName) -> Dictionary:
	var session: RefCounted = _session.get_ref()
	for rule: Dictionary in _data.get("restrictions", []):
		if _conditions.matches(rule.until, session):
			continue
		if rule.get("blocked_actions", []).has(String(action)) and (not rule.has("unit") or String(unit_id) == String(rule.unit) or action == &"end_turn"):
			return rule
		if action == &"use_item" and rule.has("allowed_item") and (not rule.has("unit") or String(unit_id) == String(rule.unit)):
			if String(unit_id) != String(rule.allowed_item.unit) or String(item_id) != String(rule.allowed_item.item):
				return rule
	return {}

func dispatch(trigger: String, context: Dictionary) -> String:
	if active:
		return "A scripted event is already playing."
	active = true
	var session: RefCounted = _session.get_ref()
	var completed: int = 0
	var limit: int = int(_data.get("limits", {}).get(trigger, 0))
	for event: Dictionary in _data.get("events", []):
		if String(event.trigger) != trigger:
			continue
		var key := StringName(event.state_key)
		if int(session.counters.get(key, 0)) > 0 or not _conditions.matches_all(event.get("conditions", []), session):
			continue
		var progress_key := StringName(String(key) + "/step")
		var steps: Array = event.steps
		for index in range(int(session.counters.get(progress_key, 0)), steps.size()):
			var error: String = await _runner.run_steps([steps[index]], context)
			if not error.is_empty():
				active = false
				return error
			session.counters[progress_key] = index + 1
		session.counters[key] = 1
		session.counters.erase(progress_key)
		completed += 1
		if limit > 0 and completed >= limit:
			break
	active = false
	return ""
