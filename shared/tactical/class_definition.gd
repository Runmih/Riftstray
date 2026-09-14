class_name TacticalClassDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var tier := 0
@export var priority := 0
@export var required_branch_points: Dictionary = {}


func validation_error() -> String:
	if id.is_empty():
		return "Class ID is empty."
	if display_name.strip_edges().is_empty():
		return "Class %s has no display name." % id
	if tier < 0:
		return "Class %s has a negative tier." % id
	for branch: Variant in required_branch_points:
		if StringName(branch).is_empty() or typeof(required_branch_points[branch]) != TYPE_INT or int(required_branch_points[branch]) < 0:
			return "Class %s has an invalid branch-point requirement." % id
	return ""
