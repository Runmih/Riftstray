class_name TacticalMatchupDefinition
extends Resource

@export var attacker_weapon_type: StringName
@export var defender_weapon_type: StringName
@export_range(-1, 1, 1) var value := 1


func validation_error() -> String:
	if attacker_weapon_type.is_empty() or defender_weapon_type.is_empty():
		return "Baseline matchup requires both attacker and defender weapon type IDs."
	if attacker_weapon_type == defender_weapon_type:
		return "Baseline matchup %s versus itself is invalid." % attacker_weapon_type
	if value != -1 and value != 1:
		return "Baseline matchup %s versus %s has invalid value %d; use -1 or 1, and omit neutral pairs." % [attacker_weapon_type, defender_weapon_type, value]
	return ""
