class_name CrossworldDataService
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://crossworld.json"

var _storage_path: String
var _document: Dictionary = {}
var _writes_blocked := false
var _load_notice := ""
var _last_error := ""
var _last_write_persisted := true


func _init(storage_path: String = DEFAULT_PATH) -> void:
	_storage_path = storage_path
	load_from_disk()


func load_from_disk() -> void:
	_document = _empty_document()
	_writes_blocked = false
	_load_notice = ""
	_last_error = ""
	_last_write_persisted = true

	if not FileAccess.file_exists(_storage_path):
		_recover_missing_primary_from_backup()
		return

	var file := FileAccess.open(_storage_path, FileAccess.READ)
	if file == null:
		_last_error = "Crossworld data could not be read: %s" % error_string(FileAccess.get_open_error())
		_writes_blocked = true
		return

	var raw_text := file.get_as_text()
	file = null
	var parser := JSON.new()
	var parse_error := parser.parse(raw_text)
	if parse_error != OK:
		_recover_malformed("JSON parse error on line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return

	var root_error := _validate_root_and_schema(parser.data)
	if not root_error.is_empty():
		_recover_malformed(root_error)
		return

	var loaded_document: Dictionary = parser.data
	var version := int(loaded_document["schema_version"])
	if version > SCHEMA_VERSION:
		_document = loaded_document.duplicate(true)
		_writes_blocked = true
		_load_notice = "Crossworld data uses newer schema version %d; writes are disabled." % version
		return
	if version < SCHEMA_VERSION:
		_recover_malformed("Unsupported older schema version %d; an explicit migration is required." % version)
		return

	var layout_error := _validate_current_layout(loaded_document)
	if not layout_error.is_empty():
		_recover_malformed(layout_error)
		return
	_document = loaded_document.duplicate(true)


func get_fact(world_id: StringName, key: StringName, default_value: Variant = null) -> Variant:
	var worlds_value: Variant = _document.get("worlds")
	if typeof(worlds_value) != TYPE_DICTIONARY:
		return _copy_json_value(default_value)
	var worlds: Dictionary = worlds_value
	var namespace_value: Variant = worlds.get(String(world_id))
	if typeof(namespace_value) != TYPE_DICTIONARY:
		return _copy_json_value(default_value)
	var world_facts: Dictionary = namespace_value
	if not world_facts.has(String(key)):
		return _copy_json_value(default_value)
	return _copy_json_value(world_facts[String(key)])


func set_world_fact(world_id: StringName, key: StringName, value: Variant) -> bool:
	_last_error = ""
	var normalized_world_id := String(world_id).strip_edges()
	var normalized_key := String(key).strip_edges()
	if _writes_blocked:
		_last_write_persisted = false
		_last_error = "Crossworld data is read-only because its schema is incompatible."
		return false
	if normalized_world_id.is_empty() or normalized_key.is_empty():
		_last_write_persisted = false
		_last_error = "Crossworld fact IDs and keys must be nonempty."
		return false
	if not _is_json_compatible(value):
		_last_write_persisted = false
		_last_error = "Crossworld fact '%s.%s' is not JSON-compatible." % [normalized_world_id, normalized_key]
		return false

	var worlds: Dictionary = _document["worlds"]
	var world_facts: Dictionary = {}
	if worlds.has(normalized_world_id):
		world_facts = (worlds[normalized_world_id] as Dictionary).duplicate(true)
	world_facts[normalized_key] = _copy_json_value(value)
	worlds[normalized_world_id] = world_facts
	_document["worlds"] = worlds

	_last_write_persisted = _write_document()
	if not _last_write_persisted and _last_error.is_empty():
		_last_error = "Crossworld fact changed in memory but could not be saved."
	return _last_write_persisted


func get_status_message() -> String:
	var messages: PackedStringArray = []
	if not _load_notice.is_empty():
		messages.append(_load_notice)
	if not _last_error.is_empty():
		messages.append(_last_error)
	return " ".join(messages)


func was_last_write_persisted() -> bool:
	return _last_write_persisted


func _write_document() -> bool:
	var temporary_path := _storage_path + ".tmp"
	var backup_path := _storage_path + ".bak"
	var temporary_file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		_last_error = "Crossworld data changed in memory, but the temporary save could not be opened: %s" % error_string(FileAccess.get_open_error())
		return false
	temporary_file.store_string(JSON.stringify(_document, "\t") + "\n")
	temporary_file.flush()
	var write_error := temporary_file.get_error()
	temporary_file = null
	if write_error != OK:
		_last_error = "Crossworld data changed in memory, but the temporary save failed: %s" % error_string(write_error)
		return false

	var absolute_storage := ProjectSettings.globalize_path(_storage_path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var moved_primary := false
	if FileAccess.file_exists(_storage_path):
		if FileAccess.file_exists(backup_path):
			var remove_error := DirAccess.remove_absolute(absolute_backup)
			if remove_error != OK:
				_last_error = "Crossworld backup could not be replaced: %s" % error_string(remove_error)
				return false
		var backup_error := DirAccess.rename_absolute(absolute_storage, absolute_backup)
		if backup_error != OK:
			_last_error = "Crossworld data could not be moved to its backup: %s" % error_string(backup_error)
			return false
		moved_primary = true

	var replace_error := DirAccess.rename_absolute(absolute_temporary, absolute_storage)
	if replace_error != OK:
		if moved_primary:
			DirAccess.copy_absolute(absolute_backup, absolute_storage)
		_last_error = "Crossworld data changed in memory, but replacing the save failed: %s" % error_string(replace_error)
		return false
	return true


func _recover_malformed(reason: String) -> void:
	_document = _empty_document()
	var recovery_path := _next_recovery_path()
	var preserve_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_storage_path),
		ProjectSettings.globalize_path(recovery_path)
	)
	if preserve_error != OK:
		_writes_blocked = true
		_last_error = "Malformed crossworld data was not changed, but could not be preserved separately (%s). Writes are disabled. %s" % [error_string(preserve_error), reason]
		return

	_load_notice = "Malformed crossworld data was preserved as %s. %s" % [recovery_path.get_file(), reason]
	_try_restore_backup()


func _recover_missing_primary_from_backup() -> void:
	var backup_path := _storage_path + ".bak"
	if not FileAccess.file_exists(backup_path):
		return
	var backup_document: Variant = _load_supported_document(backup_path)
	if typeof(backup_document) != TYPE_DICTIONARY:
		_load_notice = "Crossworld data is missing and its backup is not a supported valid document; empty data is active."
		return
	_document = (backup_document as Dictionary).duplicate(true)
	_load_notice = "Crossworld data was missing and recovered from the last-known-good backup."
	var restore_error := _restore_primary_from_backup(backup_path)
	if restore_error != OK:
		_last_error = "Recovered data is active in memory, but the primary file could not be restored: %s" % error_string(restore_error)
	else:
		_load_notice += " The primary file was restored while preserving the backup."


func _try_restore_backup() -> void:
	var backup_path := _storage_path + ".bak"
	if not FileAccess.file_exists(backup_path):
		return
	var backup_document: Variant = _load_supported_document(backup_path)
	if typeof(backup_document) != TYPE_DICTIONARY:
		return
	_document = (backup_document as Dictionary).duplicate(true)
	_load_notice += " Recovered the last-known-good backup."
	var restore_error := _restore_primary_from_backup(backup_path)
	if restore_error != OK:
		_last_error = "The recovered backup is active in memory, but the primary file could not be restored: %s" % error_string(restore_error)
	else:
		_load_notice += " The primary file was restored while preserving the backup."


func _load_supported_document(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var raw_text := file.get_as_text()
	file = null
	var parser := JSON.new()
	if parser.parse(raw_text) != OK:
		return null
	if not _validate_root_and_schema(parser.data).is_empty():
		return null
	var document: Dictionary = parser.data
	if int(document["schema_version"]) != SCHEMA_VERSION:
		return null
	if not _validate_current_layout(document).is_empty():
		return null
	return document.duplicate(true)


func _restore_primary_from_backup(backup_path: String) -> Error:
	var temporary_path := _storage_path + ".recovery.tmp"
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	if FileAccess.file_exists(temporary_path):
		var remove_error := DirAccess.remove_absolute(absolute_temporary)
		if remove_error != OK:
			return remove_error
	var copy_error := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(backup_path),
		absolute_temporary
	)
	if copy_error != OK:
		return copy_error
	var replace_error := DirAccess.rename_absolute(
		absolute_temporary,
		ProjectSettings.globalize_path(_storage_path)
	)
	if replace_error != OK:
		DirAccess.remove_absolute(absolute_temporary)
	return replace_error


func _next_recovery_path() -> String:
	var base := "%s.invalid-%d" % [_storage_path, int(Time.get_unix_time_from_system())]
	var candidate := base + ".json"
	var suffix := 1
	while FileAccess.file_exists(candidate):
		candidate = "%s-%d.json" % [base, suffix]
		suffix += 1
	return candidate


func _validate_root_and_schema(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "The root value is not an object."
	var root: Dictionary = value
	if not root.has("schema_version"):
		return "The schema_version field is missing."
	var version_value: Variant = root["schema_version"]
	if typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT:
		return "The schema_version field is not a number."
	if float(version_value) != floor(float(version_value)):
		return "The schema_version field is not an integer."
	return ""


func _validate_current_layout(value: Variant) -> String:
	var root: Dictionary = value
	if not root.has("worlds") or typeof(root["worlds"]) != TYPE_DICTIONARY:
		return "The worlds field is not an object."
	var worlds: Dictionary = root["worlds"]
	for world_key: Variant in worlds.keys():
		if typeof(world_key) != TYPE_STRING:
			return "A world namespace key is not a string."
		if typeof(worlds[world_key]) != TYPE_DICTIONARY:
			return "World namespace '%s' is not an object." % String(world_key)
		if not _is_json_compatible(worlds[world_key]):
			return "World namespace '%s' contains a non-JSON value." % String(world_key)
	return ""


func _is_json_compatible(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(float(value))
		TYPE_ARRAY:
			for item: Variant in value:
				if not _is_json_compatible(item):
					return false
			return true
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			for dictionary_key: Variant in dictionary.keys():
				if typeof(dictionary_key) != TYPE_STRING or not _is_json_compatible(dictionary[dictionary_key]):
					return false
			return true
		_:
			return false


func _copy_json_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_DICTIONARY:
		return value.duplicate(true)
	return value


func _empty_document() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"worlds": {},
	}
