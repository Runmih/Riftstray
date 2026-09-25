extends Control

signal return_to_shell

const SaveSlots = preload("res://worlds/red_alchemist/system/save/save_slots.gd")
const MapScene = preload("res://worlds/red_alchemist/display/map/map.tscn")

const Locations = preload("res://worlds/red_alchemist/system/chapter/campaign_locations.gd")
const EndScreen = preload("res://worlds/red_alchemist/display/end_of_content/end_of_content.tscn")
var end_screen: Control
var saves = SaveSlots.new()
var map_screen: Node2D
var error_dialog: AcceptDialog

func _ready() -> void:
	$Display.return_requested.connect(func(): return_to_shell.emit())
	$Display.new_game_requested.connect(_refresh_slots)
	$Display.new_game_configured.connect(_create_game)
	$Display.load_game_requested.connect(_refresh_slots)
	$Display.load_slot_requested.connect(_load_game)
	$Display.delete_slot_requested.connect(_delete_game)
	error_dialog = AcceptDialog.new()
	error_dialog.title = "Save File Error"
	add_child(error_dialog)
	error_dialog.confirmed.connect(_restore_focus)
	error_dialog.canceled.connect(_restore_focus)

func start(_context: WorldContext) -> void:
	pass

func _refresh_slots() -> void:
	$Display.set_slots(saves.list_slots())

func _create_game(slot: int, difficulty: StringName, mode: StringName) -> void:
	if map_screen != null:
		return
	if not saves.create_game(slot, difficulty, mode):
		_refresh_slots()
		_show_save_error()
		return
	_open_map()
	if map_screen != null and not saves.save_current(map_screen.capture_save()):
		_show_save_error()

func _open_map() -> void:
	var route: Dictionary = Locations.find(String(saves.current_data.story.location))
	if route.get("type") == "end_of_content":
		_show_end_screen()
		return
	if route.get("type") != "chapter":
		saves.last_error = "The saved location is unavailable."
		_show_save_error()
		return
	$Display.hide()
	map_screen = MapScene.instantiate()
	map_screen.chapter_source = String(route.source)
	map_screen.saved_campaign = saves.current_data.duplicate(true)
	add_child(map_screen)
	if not map_screen.load_error.is_empty():
		saves.last_error = map_screen.load_error
		remove_child(map_screen)
		map_screen.queue_free()
		map_screen = null
		$Display.show_start()
		_show_save_error()
		return
	map_screen.save_and_return_requested.connect(_save_and_return)
	map_screen.focus_default()

func _save_and_return() -> void:
	if map_screen == null:
		return
	if not saves.save_current(map_screen.capture_save()):
		_show_save_error()
		return
	remove_child(map_screen)
	map_screen.queue_free()
	map_screen = null
	if Locations.find(String(saves.current_data.story.location)).get("type") == "end_of_content":
		_show_end_screen()
	else:
		$Display.show_start()

func _show_save_error() -> void:
	error_dialog.dialog_text = saves.last_error
	error_dialog.popup_centered(Vector2i(440, 160))

func _restore_focus() -> void:
	if map_screen != null:
		map_screen.focus_default()
	else:
		$Display._restore_focus()


func _load_game(slot: int) -> void:
	if map_screen != null:
		return
	if not saves.load_game(slot):
		_refresh_slots()
		_show_save_error()
		return
	_open_map()

func _delete_game(slot: int) -> void:
	var deleted: bool = saves.delete_game(slot)
	_refresh_slots()
	if not deleted:
		_show_save_error()
	else:
		_restore_focus()



func _show_end_screen() -> void:
	$Display.hide()
	end_screen = EndScreen.instantiate()
	end_screen.return_requested.connect(_return_from_end)
	add_child(end_screen)

func _return_from_end() -> void:
	if end_screen != null:
		remove_child(end_screen)
		end_screen.queue_free()
		end_screen = null
	$Display.show_start()