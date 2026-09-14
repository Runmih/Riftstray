class_name TacticalCombatConstants
extends RefCounted

const REACTION_RIPOSTE: StringName = &"riposte"
const DAMAGE_PHYSICAL: StringName = &"physical"
const DAMAGE_MAGICAL: StringName = &"magical"
const STRIKE_INITIATING: StringName = &"initiating"
const STRIKE_RIPOSTE: StringName = &"riposte"
const STRIKE_NORMAL_COUNTER: StringName = &"normal_counter"
const STRIKE_SPEED_FOLLOW_UP: StringName = &"speed_follow_up"
const SUPPORTED_REACTION_IDS: Array[StringName] = [REACTION_RIPOSTE]


static func is_supported_reaction(reaction_id: StringName) -> bool:
	return SUPPORTED_REACTION_IDS.has(reaction_id)


static func supported_reaction_ids_text() -> String:
	var ids: PackedStringArray = []
	for reaction_id: StringName in SUPPORTED_REACTION_IDS:
		ids.append(String(reaction_id))
	return ", ".join(ids)
