extends RefCounted

const MapDefinition = preload("res://worlds/red_alchemist/gameplay/map/map_definition.gd")
const Spawn = preload("res://worlds/red_alchemist/gameplay/npc/npc_spawn.gd")
const Win = preload("res://worlds/red_alchemist/gameplay/win/win_manager.gd")
const Defeat = preload("res://worlds/red_alchemist/gameplay/defeat/defeat_manager.gd")
const CitizenCount = preload("res://worlds/red_alchemist/gameplay/conditions/checks/citizen_count.gd")
const UnitDead = preload("res://worlds/red_alchemist/gameplay/conditions/checks/unit_dead.gd")
const ReachDestination = preload("res://worlds/red_alchemist/gameplay/npc/behavior/reach_destination.gd")
const HuntTarget = preload("res://worlds/red_alchemist/gameplay/npc/behavior/hunt_target.gd")
var last_error: String = ""

func read(path: String) -> Dictionary:
	last_error = ""
	var chapter: Dictionary = _json(path)
	if chapter.is_empty():
		return {}
	var folder: String = path.get_base_dir()
	for key: String in ["map", "placements", "objectives", "events"]:
		chapter[key] = _json(folder.path_join(String(chapter.get(key, ""))))
	if not last_error.is_empty():
		return {}
	return chapter

func map_definition(data: Dictionary) -> Resource:
	var result := MapDefinition.new()
	for path: String in data.terrains:
		result.terrains.append(load(path))
	result.rows = PackedStringArray(data.rows)
	return result

func placements(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for entry: Dictionary in data.units:
		var spawn := Spawn.new()
		spawn.id = StringName(entry.id)
		spawn.template = load(String(entry.template))
		spawn.gender = StringName(entry.get("gender", ""))
		spawn.display_name = String(entry.get("display_name", ""))
		spawn.level = int(entry.get("level", 0))
		spawn.cell = cell(entry.cell)
		var behavior: Dictionary = entry.get("behavior", {})
		match String(behavior.get("type", "")):
			"reach_destination":
				spawn.behavior = ReachDestination.new()
				spawn.behavior.destination = cell(behavior.destination)
			"hunt_target":
				spawn.behavior = HuntTarget.new()
				spawn.behavior.target_id = StringName(behavior.target_id)
		result[String(entry.id)] = spawn
	return result

func objectives(data: Dictionary, victory: bool) -> Resource:
	var result: Resource = Win.new() if victory else Defeat.new()
	result.require_all = bool(data.require_all)
	for entry: Dictionary in data.checks:
		var check: Resource
		match String(entry.type):
			"citizen_count":
				check = CitizenCount.new()
				check.state = String(entry.state)
				check.comparison = String(entry.comparison)
				check.threshold = int(entry.threshold)
			"unit_dead":
				check = UnitDead.new()
				check.unit_id = StringName(entry.unit_id)
		result.checks.append(check)
	return result

func cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Could not open chapter data: " + path
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		last_error = "Invalid chapter data: " + path
		return {}
	return parser.data
