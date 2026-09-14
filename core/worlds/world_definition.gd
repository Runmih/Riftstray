class_name WorldDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var entry_scene: PackedScene


func validation_error() -> String:
	var normalized_id := String(id).strip_edges()
	if normalized_id.is_empty():
		return "World ID is empty."
	if display_name.strip_edges().is_empty():
		return "World '%s' has no display name." % normalized_id
	if entry_scene == null:
		return "World '%s' has no entry scene." % normalized_id
	if not entry_scene.can_instantiate():
		return "World '%s' entry scene cannot be instantiated." % normalized_id
	return ""
