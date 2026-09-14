extends RefCounted

signal line_changed(line: Dictionary, index: int)
signal finished
var last_error: String = ""
var source: String = ""
var index: int = 0
var active: bool = false
var _lines: Array[Dictionary] = []

func start(path: String, start_index: int = 0) -> bool:
	last_error = ""
	if active:
		last_error = "A dialogue is already active."
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Could not open dialogue: " + path
		return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		last_error = "Dialogue JSON is malformed: " + path
		return false
	var data: Dictionary = parser.data
	if not data.get("speakers") is Dictionary or not data.get("lines") is Array or data.lines.is_empty():
		last_error = "Dialogue requires speakers and at least one line."
		return false
	var prepared: Array[Dictionary] = []
	for entry in data.lines:
		if not entry is Dictionary or not entry.get("text") is String or not entry.get("speaker") is String or not data.speakers.get(entry.speaker) is Dictionary:
			last_error = "Dialogue contains an invalid message or speaker."
			return false
		var speaker: Dictionary = data.speakers[entry.speaker]
		if not speaker.get("name") is String or not speaker.get("portrait", "") is String or not entry.get("portrait", "") is String:
			last_error = "Dialogue speaker names and portrait references must be text."
			return false
		prepared.append({"speaker": entry.speaker, "name": speaker.name, "text": entry.text, "portrait": entry.get("portrait", speaker.get("portrait", ""))})
	if start_index < 0 or start_index >= prepared.size():
		last_error = "The saved dialogue position is unavailable."
		return false
	_lines = prepared
	source = path
	index = start_index
	active = true
	line_changed.emit(_lines[index].duplicate(), index)
	return true

func advance() -> void:
	if not active:
		return
	index += 1
	if index >= _lines.size():
		active = false
		finished.emit()
	else:
		line_changed.emit(_lines[index].duplicate(), index)

func show_message(speaker_name: String, text: String) -> bool:
	if active:
		return false
	source = ""
	index = 0
	_lines = [{"speaker": "", "name": speaker_name, "text": text, "portrait": ""}]
	active = true
	line_changed.emit(_lines[0].duplicate(), index)
	return true
