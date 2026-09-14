class_name TacticalSkillDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var branch_id: StringName
@export var section_id: StringName
@export var display_order := 0
@export var point_cost := 1
@export var prerequisites: Array[StringName] = []
@export var effects: Array[TacticalEffectDefinition] = []


func validation_error(attribute_ids: Array[StringName]) -> String:
	if id.is_empty():
		return "Skill ID is empty."
	if display_name.strip_edges().is_empty():
		return "Skill %s has no display name." % id
	if branch_id.is_empty():
		return "Skill %s has no branch ID." % id
	if display_order < 0:
		return "Skill %s has a negative display order." % id
	if point_cost <= 0:
		return "Skill %s has a nonpositive point cost." % id
	var seen_prerequisites: Dictionary = {}
	for prerequisite: StringName in prerequisites:
		if prerequisite.is_empty():
			return "Skill %s has an empty prerequisite ID." % id
		if seen_prerequisites.has(prerequisite):
			return "Skill %s repeats prerequisite %s." % [id, prerequisite]
		seen_prerequisites[prerequisite] = true
	var seen_effects: Dictionary = {}
	for effect: TacticalEffectDefinition in effects:
		if effect == null:
			return "Skill %s contains a missing effect." % id
		if seen_effects.has(effect.id):
			return "Skill %s contains duplicate effect ID %s." % [id, effect.id]
		seen_effects[effect.id] = true
		var error := effect.validation_error(attribute_ids)
		if not error.is_empty():
			return "Skill %s: %s" % [id, error]
	return ""
