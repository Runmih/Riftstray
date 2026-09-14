class_name TacticalWeaponDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var type_id: StringName
@export var might := 0
@export var accuracy := 0
@export var critical := 0
@export var weight := 0
@export var contributes_to_combat_burden := true
@export var compatible_slots: Array[StringName] = [&"main_hand"]
@export var reserved_slots: Array[StringName] = []
@export var damage_type: StringName = TacticalCombatConstants.DAMAGE_PHYSICAL
@export var minimum_range := 1
@export var maximum_range := 1
@export var enables_block := false


func validation_error() -> String:
	if id.is_empty():
		return "Equipment ID is empty."
	if display_name.strip_edges().is_empty():
		return "Equipment %s has no display name." % id
	if type_id.is_empty():
		return "Equipment %s has no type ID." % id
	if might < 0:
		return "Equipment %s has negative might." % id
	if accuracy < 0 or accuracy > 100:
		return "Equipment %s has accuracy outside 0–100." % id
	if critical < 0 or critical > 100:
		return "Equipment %s has critical chance outside 0–100." % id
	if weight < 0:
		return "Equipment %s has negative weight." % id
	if compatible_slots.is_empty():
		return "Equipment %s has no compatible slots." % id
	var seen_slots: Dictionary = {}
	for slot_id: StringName in compatible_slots:
		if slot_id.is_empty() or seen_slots.has(slot_id):
			return "Equipment %s has an empty or duplicate compatible slot." % id
		seen_slots[slot_id] = true
	for slot_id: StringName in reserved_slots:
		if slot_id.is_empty() or seen_slots.has(slot_id):
			return "Equipment %s has an empty, duplicate, or self-reserved slot." % id
		seen_slots[slot_id] = true
	if damage_type != TacticalCombatConstants.DAMAGE_PHYSICAL and damage_type != TacticalCombatConstants.DAMAGE_MAGICAL:
		return "Equipment %s has unsupported damage type %s; expected physical or magical." % [id, damage_type]
	if minimum_range < 0 or maximum_range < minimum_range:
		return "Equipment %s has an invalid range." % id
	return ""


func is_offensive() -> bool:
	return maximum_range > 0
