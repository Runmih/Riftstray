class_name TacticalSkillSectionDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var display_order := 0


func validation_error() -> String:
	if id.is_empty():
		return "Skill section ID is empty."
	if display_name.strip_edges().is_empty():
		return "Skill section %s has no display name." % id
	if display_order < 0:
		return "Skill section %s has a negative display order." % id
	return ""
