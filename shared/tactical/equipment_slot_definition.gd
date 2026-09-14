class_name TacticalEquipmentSlotDefinition
extends Resource

@export var id: StringName
@export var display_name: String


func validation_error() -> String:
	if id.is_empty():
		return "Equipment slot ID is empty."
	if display_name.strip_edges().is_empty():
		return "Equipment slot %s has no display name." % id
	return ""
