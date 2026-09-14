class_name SettingsService
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://settings.json"
const DEFAULT_MASTER_VOLUME := 0.8
const DEFAULT_FULLSCREEN := false

var master_volume: float = DEFAULT_MASTER_VOLUME
var fullscreen: bool = DEFAULT_FULLSCREEN

var _storage_path: String
var _apply_immediately: bool
var _status_message := ""


func _init(storage_path: String = DEFAULT_PATH, apply_immediately: bool = true) -> void:
	_storage_path = storage_path
	_apply_immediately = apply_immediately
	load_from_disk()
	if _apply_immediately:
		apply_all()


func load_from_disk() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	fullscreen = DEFAULT_FULLSCREEN
	_status_message = ""
	if not FileAccess.file_exists(_storage_path):
		return

	var file := FileAccess.open(_storage_path, FileAccess.READ)
	if file == null:
		_status_message = "Settings could not be read; defaults are active."
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		_status_message = "Settings are invalid; defaults are active."
		return
	if typeof(parser.data) != TYPE_DICTIONARY:
		_status_message = "Settings are invalid; defaults are active."
		return

	var document: Dictionary = parser.data
	var version_value: Variant = document.get("schema_version")
	var volume_value: Variant = document.get("master_volume")
	var fullscreen_value: Variant = document.get("fullscreen")
	if (
		typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT
		or int(version_value) != SCHEMA_VERSION
		or (typeof(volume_value) != TYPE_INT and typeof(volume_value) != TYPE_FLOAT)
		or float(volume_value) < 0.0
		or float(volume_value) > 1.0
		or typeof(fullscreen_value) != TYPE_BOOL
	):
		_status_message = "Settings are invalid or incompatible; defaults are active."
		return

	master_volume = float(volume_value)
	fullscreen = bool(fullscreen_value)


func set_master_volume(value: float) -> bool:
	master_volume = clampf(value, 0.0, 1.0)
	if _apply_immediately:
		_apply_volume()
	return _save()


func set_fullscreen(value: bool) -> bool:
	fullscreen = value
	if _apply_immediately:
		_apply_fullscreen()
	return _save()


func apply_all() -> void:
	_apply_volume()
	_apply_fullscreen()


func get_status_message() -> String:
	return _status_message


func _apply_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		_status_message = "The Master audio bus is unavailable."
		return
	AudioServer.set_bus_mute(master_bus, master_volume <= 0.0)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.0001)))


func _apply_fullscreen() -> void:
	if String(DisplayServer.get_name()).to_lower() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _save() -> bool:
	var document := {
		"schema_version": SCHEMA_VERSION,
		"master_volume": master_volume,
		"fullscreen": fullscreen,
	}
	var temporary_path := _storage_path + ".tmp"
	var backup_path := _storage_path + ".bak"
	var temporary_file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		_status_message = "Settings changed in memory but could not be saved: %s" % error_string(FileAccess.get_open_error())
		return false
	temporary_file.store_string(JSON.stringify(document, "\t") + "\n")
	temporary_file.flush()
	var write_error := temporary_file.get_error()
	temporary_file = null
	if write_error != OK:
		_status_message = "Settings changed in memory but could not be saved: %s" % error_string(write_error)
		return false

	var absolute_storage := ProjectSettings.globalize_path(_storage_path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var moved_primary := false
	if FileAccess.file_exists(_storage_path):
		if FileAccess.file_exists(backup_path):
			var remove_error := DirAccess.remove_absolute(absolute_backup)
			if remove_error != OK:
				_status_message = "Settings changed in memory but the backup could not be replaced."
				return false
		var backup_error := DirAccess.rename_absolute(absolute_storage, absolute_backup)
		if backup_error != OK:
			_status_message = "Settings changed in memory but the previous file could not be backed up."
			return false
		moved_primary = true

	var replace_error := DirAccess.rename_absolute(absolute_temporary, absolute_storage)
	if replace_error != OK:
		if moved_primary:
			DirAccess.copy_absolute(absolute_backup, absolute_storage)
		_status_message = "Settings changed in memory but replacing the save failed: %s" % error_string(replace_error)
		return false
	_status_message = ""
	return true
