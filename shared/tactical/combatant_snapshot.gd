class_name TacticalCombatantSnapshot
extends RefCounted

var id: StringName
var display_name: String
var alliance_id: StringName
var grid_position: Vector2i
var movement_profile_id: StringName = &"ground"
var terrain_hit_bonus := 0
var terrain_avoid_bonus := 0
var present := true
var current_hp := 1
var maximum_hp := 1
var strength := 0
var skill := 0
var speed := 0
var defense := 0
var magic := 0
var resistance := 0
var equipped_weight := 0
var pending_stun := false
var primary_weapon: TacticalWeaponDefinition
var block_capable := false
var effects: Array[TacticalEffectDefinition] = []


func is_alive_and_present() -> bool:
	return present and current_hp > 0


func has_reaction(reaction_id: StringName) -> bool:
	for effect: TacticalEffectDefinition in effects:
		if (
			effect.type == TacticalEffectDefinition.Type.REACTION_PERMISSION
			and effect.reaction_id == reaction_id
			and (effect.required_weapon_type.is_empty() or (primary_weapon != null and effect.required_weapon_type == primary_weapon.type_id))
		):
			return true
	return false


func duplicate_snapshot() -> TacticalCombatantSnapshot:
	var copy := TacticalCombatantSnapshot.new()
	copy.id = id
	copy.display_name = display_name
	copy.alliance_id = alliance_id
	copy.grid_position = grid_position
	copy.movement_profile_id = movement_profile_id
	copy.terrain_hit_bonus = terrain_hit_bonus
	copy.terrain_avoid_bonus = terrain_avoid_bonus
	copy.present = present
	copy.current_hp = current_hp
	copy.maximum_hp = maximum_hp
	copy.strength = strength
	copy.skill = skill
	copy.speed = speed
	copy.defense = defense
	copy.magic = magic
	copy.resistance = resistance
	copy.equipped_weight = equipped_weight
	copy.pending_stun = pending_stun
	copy.primary_weapon = primary_weapon
	copy.block_capable = block_capable
	copy.effects = effects.duplicate()
	return copy
