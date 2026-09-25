extends RefCounted

const SaveFile = preload("res://worlds/red_alchemist/system/save/save_file.gd")
const SLOT_COUNT = 6
const State = preload("res://worlds/red_alchemist/system/save/campaign_state.gd")
const Locations = preload("res://worlds/red_alchemist/system/chapter/campaign_locations.gd")

var active_slot := 0
var current_data: Dictionary = {}
var last_error := ""

func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for number in range(1, SLOT_COUNT + 1):
		var file = _file(number)
		var occupied: bool = file.exists()
		var label := "Slot %d — Empty" % number
		var loadable := false
		if occupied:
			var data: Dictionary = file.load_data()
			loadable = file.last_error.is_empty() and _data_error(data).is_empty()
			label = "Slot %d — Unavailable" % number if not loadable else "Slot %d — %s / %s" % [number, String(data.get("difficulty", "Unknown")).capitalize(), String(data.get("mode", "Unknown")).capitalize()]
		slots.append({"id": number, "label": label, "occupied": occupied, "loadable": loadable})
	return slots

func create_game(slot: int, difficulty: StringName, mode: StringName) -> bool:
	last_error = ""
	if slot < 1 or slot > SLOT_COUNT or not difficulty in [&"easy", &"normal", &"hard"] or not mode in [&"casual", &"classic"]:
		last_error = "Choose a valid slot, difficulty, and game mode."
		return false
	var file = _file(slot)
	if file.exists():
		last_error = "This slot is occupied. Choose an empty slot."
		return false
	var timestamp := int(Time.get_unix_time_from_system())
	var data := {"difficulty": String(difficulty), "mode": String(mode), "state_version": 2, "story": {"location": Locations.initial(), "flags": {}}, "created_at": timestamp, "saved_at": timestamp}
	if not file.save_data(data):
		last_error = file.last_error
		return false
	active_slot = slot
	current_data = data
	return true

func save_current(state: Dictionary = {}) -> bool:
	last_error = ""
	if active_slot < 1 or active_slot > SLOT_COUNT or current_data.is_empty():
		last_error = "No active game to save."
		return false
	var candidate := current_data.duplicate(true)
	if not state.is_empty():
		candidate.merge(state, true)
		candidate["state_version"] = 2
	candidate["saved_at"] = int(Time.get_unix_time_from_system())
	var file = _file(active_slot)
	if not file.save_data(candidate):
		last_error = file.last_error
		return false
	current_data = candidate
	return true

func _file(slot: int):
	return SaveFile.new("user://worlds/red_alchemist/saves/save_%02d.json" % slot)

func load_game(slot: int) -> bool:
	last_error = ""
	if slot < 1 or slot > SLOT_COUNT:
		last_error = "Invalid save slot."
		return false
	var file = _file(slot)
	var data: Dictionary = file.load_data()
	last_error = file.last_error
	if last_error.is_empty():
		last_error = _data_error(data)
	if not last_error.is_empty():
		return false
	var codec := State.new()
	var upgraded: Dictionary = codec.upgrade(data)
	if not codec.last_error.is_empty():
		last_error = codec.last_error
		return false
	active_slot = slot
	current_data = upgraded
	return true

func delete_game(slot: int) -> bool:
	last_error = ""
	if slot < 1 or slot > SLOT_COUNT:
		last_error = "Invalid save slot."
		return false
	var file = _file(slot)
	if not file.delete_data():
		last_error = file.last_error
		return false
	if active_slot == slot:
		active_slot = 0
		current_data = {}
	return true

func _data_error(data: Dictionary) -> String:
	if int(data.get("state_version", 0)) > 2:
		return "This save needs a newer game version."
	if not data.get("difficulty") in ["easy", "normal", "hard"] or not data.get("mode") in ["casual", "classic"]:
		return "This save contains unsupported game data."
	if not data.get("story") is Dictionary:
		return "This save has no story location."
	var story: Dictionary = State.new().clean_story(data.story)
	if Locations.find(String(story.get("location", ""))).is_empty():
		return "The saved story location is unavailable."
	return ""

