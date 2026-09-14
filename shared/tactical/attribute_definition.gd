class_name TacticalAttributeDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var point_cost := 1
@export var allocation_gain := 1


func validation_error() -> String:
	if id.is_empty():
		return "Attribute ID is empty."
	if display_name.strip_edges().is_empty():
		return "Attribute %s has no display name." % id
	if point_cost <= 0:
		return "Attribute %s has a nonpositive point cost." % id
	if allocation_gain <= 0:
		return "Attribute %s has a nonpositive allocation gain." % id
	return ""
