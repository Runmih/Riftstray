class_name WorldCatalog
extends Resource

@export var worlds: Array[WorldDefinition] = []


func inspect_entries() -> Array[Dictionary]:
	var id_counts: Dictionary = {}
	for definition: WorldDefinition in worlds:
		if definition == null:
			continue
		var normalized_id := String(definition.id).strip_edges()
		if not normalized_id.is_empty():
			id_counts[normalized_id] = int(id_counts.get(normalized_id, 0)) + 1

	var inspected: Array[Dictionary] = []
	for definition: WorldDefinition in worlds:
		var error := "World definition is missing."
		if definition != null:
			error = definition.validation_error()
			var normalized_id := String(definition.id).strip_edges()
			if error.is_empty() and int(id_counts.get(normalized_id, 0)) > 1:
				error = "World ID '%s' is duplicated." % normalized_id
		inspected.append({
			"definition": definition,
			"is_valid": error.is_empty(),
			"error": error,
		})
	return inspected


func find_valid_definition(world_id: StringName) -> WorldDefinition:
	for entry: Dictionary in inspect_entries():
		if not bool(entry["is_valid"]):
			continue
		var definition: WorldDefinition = entry["definition"]
		if definition.id == world_id:
			return definition
	return null
