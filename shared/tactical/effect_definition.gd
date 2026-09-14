class_name TacticalEffectDefinition
extends Resource

enum Type {
	STAT_MODIFIER,
	CONDITIONAL_DUEL_MODIFIER,
	MATCHUP_OVERRIDE,
	REACTION_PERMISSION,
}

@export var id: StringName
@export var type: int = Type.STAT_MODIFIER
@export var priority := 0
@export var required_weapon_type: StringName
@export var stat_id: StringName
@export var stat_modifier := 0
@export var attack_modifier := 0
@export var hit_modifier := 0
@export var block_modifier := 0
@export var critical_modifier := 0
@export var opponent_weapon_type: StringName
@export_range(-1, 1, 1) var matchup_value := 0
@export var reaction_id: StringName


func validation_error(attribute_ids: Array[StringName]) -> String:
	if id.is_empty():
		return "Effect ID is empty."
	if type < Type.STAT_MODIFIER or type > Type.REACTION_PERMISSION:
		return "Effect %s uses an unsupported effect type." % id
	match type:
		Type.STAT_MODIFIER:
			if stat_modifier != 0 and (stat_id.is_empty() or not attribute_ids.has(stat_id)):
				return "Effect %s modifies unknown attribute %s." % [id, stat_id]
			if stat_modifier == 0 and attack_modifier == 0 and hit_modifier == 0 and block_modifier == 0 and critical_modifier == 0:
				return "Effect %s has no stat or combat modifier." % id
		Type.CONDITIONAL_DUEL_MODIFIER:
			if attack_modifier == 0 and hit_modifier == 0 and critical_modifier == 0:
				return "Conditional duel effect %s has no modifier." % id
		Type.MATCHUP_OVERRIDE:
			if required_weapon_type.is_empty() or opponent_weapon_type.is_empty():
				return "Matchup override %s requires both weapon type IDs." % id
		Type.REACTION_PERMISSION:
			if reaction_id.is_empty():
				return "Reaction effect %s has no reaction ID." % id
			if not TacticalCombatConstants.is_supported_reaction(reaction_id):
				return "Reaction effect %s uses unsupported reaction ID %s. Supported reactions: %s." % [id, reaction_id, TacticalCombatConstants.supported_reaction_ids_text()]
	return ""
