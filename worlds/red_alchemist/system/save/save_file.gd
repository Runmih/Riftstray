extends RefCounted

const FORMAT = "riftstray.red_alchemist.save"
const VERSION = 1

var last_error := ""
var _path: String

func _init(path: String = "user://worlds/red_alchemist/saves/save_01.json") -> void:
	_path = path

func exists() -> bool:
	return FileAccess.file_exists(_path) or FileAccess.file_exists(_path + ".bak")

func load_data() -> Dictionary:
	last_error = ""
	var source := _path if FileAccess.file_exists(_path) else _path + ".bak"
	if not FileAccess.file_exists(source):
		last_error = "Save file not found."
		return {}
	var document := _read_document(source)
	if not last_error.is_empty():
		return {}
	return document["data"].duplicate(true)

func save_data(data: Dictionary) -> bool:
	last_error = ""
	if exists():
		load_data()
		if not last_error.is_empty():
			return false
	var document := {"format": FORMAT, "version": VERSION, "data": data}
	var temporary := _path + ".tmp"
	var backup := _path + ".bak"
	if not _write_text(temporary, JSON.stringify(document, "\t") + "\n"):
		return false
	if FileAccess.file_exists(_path):
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(ProjectSettings.globalize_path(backup)) != OK:
			last_error = "Could not replace the save backup."
			return false
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(_path), ProjectSettings.globalize_path(backup)) != OK:
			last_error = "Could not preserve the previous save."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(_path)) != OK:
		last_error = "Could not replace the save file; the previous save remains in backup."
		return false
	return true

func _read_document(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Could not read the save file."
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		last_error = "Save file is malformed."
		return {}
	var document: Dictionary = parser.data
	if document.get("format") != FORMAT or document.get("version") != VERSION:
		last_error = "Save format is unsupported; the file was left unchanged."
		return {}
	if not document.get("data") is Dictionary:
		last_error = "Save data is malformed."
		return {}
	return document

func _write_text(path: String, text: String) -> bool:
	var directory := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(directory) != OK and not DirAccess.dir_exists_absolute(directory):
		last_error = "Could not create the save folder."
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open the save file for writing."
		return false
	file.store_string(text)
	file.flush()
	if file.get_error() != OK:
		last_error = "Could not finish writing the save file."
		return false
	return true

func delete_data() -> bool:
	last_error = ""
	for suffix: String in [".tmp", ".bak", ""]:
		var path: String = _path + suffix
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			last_error = "Could not delete the save file."
			return false
	return true
