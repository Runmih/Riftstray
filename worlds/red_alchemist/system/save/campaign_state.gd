extends RefCounted

const Spawn = preload("res://worlds/red_alchemist/gameplay/npc/npc_spawn.gd")
const Character = preload("res://worlds/red_alchemist/gameplay/character/character.gd")
const Skills = preload("res://worlds/red_alchemist/gameplay/skills/skills.gd")
var last_error: String = ""
var map_id: String = ""
var map_revision: int = 0

func capture(session: RefCounted, story: Dictionary) -> Dictionary:
	var characters: Dictionary = {}
	var placements: Dictionary = {}
	for unit in session.group.npcs:
		var items: Dictionary = {}
		for item_id in unit.inventory.items:
			items[String(item_id)] = unit.inventory.items[item_id].resource_path
		characters[String(unit.id)] = {
			"template": unit.template_path, "gender": String(unit.gender), "display_name": unit.template.display_name, "faction": String(unit.template.faction), "hp": unit.current_hp, "level": unit.level, "level_cap": unit.level_cap,
			"xp": unit.xp, "permanent_hp_loss": unit.permanent_hp_loss, "consumed_unique_items": unit.consumed_unique_items.duplicate(), "unspent_attribute_points": unit.unspent_attribute_points,
			"attributes": unit.attributes.duplicate(), "allocations": unit.allocations.duplicate(),
			"items": items, "next_item_id": unit.inventory.next_item_id(),
			"gear": unit.gear.equipped.duplicate(), "selected_skills": unit.skills.selected.duplicate()
		}
		placements[String(unit.id)] = {"cell": [unit.cell.x, unit.cell.y], "hp": unit.current_hp, "stunned": unit.stunned, "battle_bonuses": unit.battle_bonuses.duplicate(), "extra_actions": unit.extra_actions, "extra_moves": unit.extra_moves, "escaped": unit.escaped, "behavior": _behavior(unit.behavior)}
	return {"state_version": 2, "characters": player_roster(characters), "story": clean_story(story), "map_state": {
		"map_id": map_id, "revision": map_revision, "characters": characters, "units": placements, "round": session.turns.round_number,
		"phase_index": session.turns.phase_index, "phase_order": session.turns.phase_order.duplicate(),
		"actions": session.turns.actions.remaining.duplicate(), "movement": session.turns.movement.remaining.duplicate(),
		"counters": session.counters.duplicate(), "outcome": String(session.outcome),
		"rng_state": str(session.battle.rng.state)
	}}

func restore(session: RefCounted, data: Dictionary, attribute_rules: Resource) -> bool:
	last_error = ""
	if not data.get("characters") is Dictionary or not data.get("map_state") is Dictionary or not data.get("story") is Dictionary:
		return _fail("The saved campaign state is incomplete.")
	var state: Dictionary = data.map_state
	var records: Dictionary = state.get("characters", data.characters)
	if int(state.get("revision", 1)) != map_revision:
		return _fail("This save uses a different map layout. Its original data has been preserved.")
	if state.get("map_id") != map_id or not state.get("units") is Dictionary:
		return _fail("This saved map is unavailable.")
	if not state.get("phase_order") is Array or state.phase_order.is_empty() or int(state.get("phase_index", -1)) < 0 or int(state.phase_index) >= state.phase_order.size():
		return _fail("The saved turn position is invalid.")
	for field in ["actions", "movement", "counters"]:
		if not state.get(field) is Dictionary:
			return _fail("The saved map state is incomplete.")
	var restored: Array = []
	var occupied: Dictionary = {}
	for unit_id in state.units:
		if not state.units[unit_id] is Dictionary or not records.get(unit_id) is Dictionary:
			return _fail("A saved character is missing.")
		var record: Dictionary = records[unit_id]
		var placement: Dictionary = state.units[unit_id]
		for field in ["attributes", "allocations", "items", "gear", "selected_skills"]:
			if not record.get(field) is Dictionary:
				return _fail("A saved character has incomplete data.")
		if not placement.get("cell") is Array or placement.cell.size() != 2:
			return _fail("A saved character position is invalid.")
		var template: Resource = _resource(String(record.get("template", "")))
		if template == null:
			return false
		var spawn := Spawn.new()
		spawn.id = StringName(unit_id)
		spawn.template = template
		spawn.gender = StringName(record.get("gender", ""))
		spawn.display_name = String(record.get("display_name", ""))
		spawn.level = int(record.get("level", 1))
		spawn.cell = Vector2i(int(placement.cell[0]), int(placement.cell[1]))
		if not session.group.grid.contains(spawn.cell):
			return _fail("A saved character is outside this map.")
		var unit := Character.new(spawn, attribute_rules)
		unit.level = int(record.get("level", 1))
		unit.level_cap = int(record.get("level_cap", template.level_cap))
		unit.xp = maxi(0, int(record.get("xp", 0)))
		unit.permanent_hp_loss = int(record.get("permanent_hp_loss", 0))
		for item_id in record.get("consumed_unique_items", []):
			unit.consumed_unique_items.append(StringName(item_id))
		unit.battle_bonuses = _numeric_dictionary(placement.get("battle_bonuses", {}))
		unit.extra_actions = int(placement.get("extra_actions", 0))
		unit.extra_moves = int(placement.get("extra_moves", 0))
		unit.unspent_attribute_points = maxi(0, int(record.get("unspent_attribute_points", 0)))
		unit.attributes = _numeric_dictionary(record.attributes)
		unit.allocations = _numeric_dictionary(record.allocations)
		unit.current_hp = int(placement.get("hp", 0))
		unit.stunned = bool(placement.get("stunned", false))
		unit.escaped = bool(placement.get("escaped", false))
		if unit.level < 1 or unit.level > unit.level_cap or int(unit.attributes.get(&"max_hp", 0)) < 1 or unit.current_hp < 0 or unit.current_hp > int(unit.attributes[&"max_hp"]):
			return _fail("A saved character has invalid progression or HP.")
		if unit.current_hp > 0 and not unit.escaped:
			if occupied.has(unit.cell):
				return _fail("Two saved characters occupy the same tile.")
			occupied[unit.cell] = true
		var restored_items: Dictionary = {}
		for item_id in record.items:
			var item: Resource = _resource(String(record.items[item_id]))
			if item == null:
				return false
			restored_items[StringName(item_id)] = item
		unit.inventory.restore_items(restored_items, int(record.get("next_item_id", 1)))
		unit.gear.equipped.clear()
		for slot in record.gear:
			var item_id := StringName(record.gear[slot])
			if unit.gear.is_equipped(item_id):
				continue
			if not unit.gear.equip(item_id, StringName(slot)):
				return _fail("Saved equipment cannot be restored: " + unit.gear.last_error)
		unit.skills = Skills.new(unit, record.selected_skills)
		if unit.skills.selected.size() != record.selected_skills.size():
			return _fail("A saved skill selection no longer matches its family.")
		unit.behavior = _restore_behavior(placement.get("behavior", {}))
		if not last_error.is_empty():
			return false
		restored.append(unit)
	if restored.is_empty():
		return _fail("The saved map has no characters.")
	session.group.npcs = restored
	session.turns.phase_order.clear()
	for faction in state.phase_order:
		session.turns.phase_order.append(StringName(faction))
	session.turns.phase_index = int(state.phase_index)
	session.turns.round_number = maxi(1, int(state.get("round", 1)))
	session.turns.actions.remaining = _numeric_dictionary(state.actions)
	session.turns.movement.remaining = _numeric_dictionary(state.movement)
	session.counters = _numeric_dictionary(state.counters)
	session.outcome = StringName(state.get("outcome", ""))
	session.battle.rng.state = String(state.get("rng_state", "0")).to_int()
	session.group.sync_occupancy()
	return true

func _numeric_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[StringName(key)] = int(source[key])
	return result

func _resource(path: String) -> Resource:
	if path == "res://worlds/red_alchemist/src/character/sophie/sophie.tres":
		path = "res://worlds/red_alchemist/src/character/main/sophie/sophie.tres"
	path = _saved_path(path)
	if path == "res://worlds/red_alchemist/gameplay/npc/kharazad/assassin/assassin.tres":
		path = "res://worlds/red_alchemist/gameplay/npc/kharazad/fighter/fighter.tres"
	if path == "res://worlds/red_alchemist/gameplay/npc/courtesan/sophie.tres":
		path = "res://worlds/red_alchemist/src/character/main/sophie/sophie.tres"
	if not path.begins_with("res://worlds/red_alchemist/") or not ResourceLoader.exists(path):
		_fail("Saved content is unavailable: " + path)
		return null
	return load(path)

func _behavior(behavior: Resource) -> Dictionary:
	if behavior == null:
		return {}
	var values: Dictionary = {}
	for property in behavior.get_property_list():
		if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (int(property.usage) & PROPERTY_USAGE_STORAGE):
			continue
		var value: Variant = behavior.get(property.name)
		if value is Vector2i:
			values[property.name] = {"cell": [value.x, value.y]}
		else:
			values[property.name] = value
	return {"script": behavior.get_script().resource_path, "values": values}

func _restore_behavior(data: Dictionary) -> Resource:
	if data.is_empty():
		return null
	var path: String = _saved_path(String(data.get("script", "")))
	if not path.begins_with("res://worlds/red_alchemist/gameplay/npc/behavior/") or not ResourceLoader.exists(path) or not data.get("values") is Dictionary:
		_fail("Saved NPC behavior is unavailable.")
		return null
	var behavior: Resource = load(path).new()
	for key in data["values"]:
		var value: Variant = data["values"][key]
		if value is Dictionary and value.get("cell") is Array and value.cell.size() == 2:
			value = Vector2i(int(value.cell[0]), int(value.cell[1]))
		behavior.set(key, value)
	return behavior

func _fail(message: String) -> bool:
	last_error = message
	return false





func clean_story(source: Dictionary) -> Dictionary:
	var result: Dictionary = source.duplicate(true)
	if not result.has("location"):
		var node: String = String(result.get("node", "battle"))
		result["location"] = String(result.get("chapter", "")) if node == "battle" else node
	result.erase("chapter")
	result.erase("node")
	result.erase("completed_chapters")
	return result

func player_roster(records: Dictionary) -> Dictionary:
	var roster: Dictionary = {}
	for id in records:
		var record: Dictionary = records[id]
		var faction: String = String(record.get("faction", ""))
		if faction.is_empty():
			var definition: Resource = _resource(String(record.get("template", "")))
			if definition == null:
				continue
			faction = String(definition.faction)
		if faction == "player":
			roster[id] = record.duplicate(true)
	return roster

func upgrade(source: Dictionary) -> Dictionary:
	var data: Dictionary = source.duplicate(true)
	data["story"] = clean_story(data.get("story", {}))
	data.erase("location")
	if data.get("map_state") is Dictionary:
		var state: Dictionary = data.map_state
		if not state.has("characters"):
			state["characters"] = data.get("characters", {}).duplicate(true)
		for id in state.get("units", {}):
			if state.characters.has(id):
				state.characters[id]["hp"] = int(state.units[id].get("hp", 0))
		data["characters"] = player_roster(state.characters)
	else:
		data["characters"] = player_roster(data.get("characters", {}))
	if data.get("chapter_start") is Dictionary:
		data.chapter_start = upgrade(data.chapter_start)
	if data.get("map_state") is Dictionary and data.map_state.get("outcome") == "victory":
		finish_roster(data.characters)
		data["map_state"] = null
		data["chapter_start"] = null
	data["state_version"] = 2
	return data

func finish_roster(roster: Dictionary) -> void:
	for record: Dictionary in roster.values():
		if int(record.get("hp", 0)) > 0:
			record["hp"] = int(record.attributes.get("max_hp", 1))

func capture_progress(session: RefCounted, story: Dictionary, chapter_start: Dictionary, previous: Dictionary, chapter: Dictionary) -> Dictionary:
	var state: Dictionary = upgrade(chapter_start) if session.outcome == &"defeat" else capture(session, story)
	var roster: Dictionary = player_roster(previous.get("characters", {}))
	roster.merge(state.characters, true)
	state.characters = roster
	state["chapter_start"] = upgrade(chapter_start)
	if session.outcome == &"victory":
		state.story = {"location": String(chapter.next_location)}
		finish_roster(state.characters)
		state["map_state"] = null
		state["chapter_start"] = null
	return state

func restore_roster(session: RefCounted, roster: Dictionary, story: Dictionary, rules: Resource) -> bool:
	var state: Dictionary = capture(session, story)
	for id in roster:
		if state.map_state.characters.has(id) and state.characters.has(id):
			state.map_state.characters[id] = roster[id].duplicate(true)
			state.map_state.units[id].hp = int(roster[id].get("hp", roster[id].attributes.get("max_hp", 1)))
	return restore(session, state, rules)
func _saved_path(path: String) -> String:
	path = path.replace("res://worlds/red_alchemist/system/display/", "res://worlds/red_alchemist/display/")
	path = path.replace("res://worlds/red_alchemist/system/gameplay/", "res://worlds/red_alchemist/gameplay/")
	path = path.replace("res://worlds/red_alchemist/system/animation/", "res://worlds/red_alchemist/display/animation/")
	path = path.replace("res://worlds/red_alchemist/system/npc/", "res://worlds/red_alchemist/gameplay/npc/")
	path = path.replace("res://worlds/red_alchemist/system/character/", "res://worlds/red_alchemist/gameplay/character/")
	path = path.replace("res://worlds/red_alchemist/system/map/", "res://worlds/red_alchemist/gameplay/map/")
	return path
