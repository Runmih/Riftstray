class_name TacticalDerivedCharacter
extends RefCounted

var character_id: StringName
var display_name: String
var level := 1
var stats: Dictionary = {}
var movement := 0
var movement_profile_id: StringName = &"ground"
var class_id: StringName
var class_display_name: String
var class_tier := 0
var primary_weapon: TacticalWeaponDefinition
var equipment: Array[TacticalWeaponDefinition] = []
var effects: Array[TacticalEffectDefinition] = []


func get_equipped_weight() -> int:
	var total := 0
	for item: TacticalWeaponDefinition in equipment:
		if item != null and item.contributes_to_combat_burden:
			total += item.weight
	return total


func get_stat(stat_id: StringName) -> int:
	return int(stats.get(stat_id, 0))


func has_block_capability() -> bool:
	for item: TacticalWeaponDefinition in equipment:
		if item.enables_block:
			return true
	return false


func has_reaction(reaction_id: StringName) -> bool:
	for effect: TacticalEffectDefinition in effects:
		if (
			effect.type == TacticalEffectDefinition.Type.REACTION_PERMISSION
			and effect.reaction_id == reaction_id
			and _weapon_requirement_matches(effect)
		):
			return true
	return false


func _weapon_requirement_matches(effect: TacticalEffectDefinition) -> bool:
	return effect.required_weapon_type.is_empty() or (
		primary_weapon != null and primary_weapon.type_id == effect.required_weapon_type
	)
