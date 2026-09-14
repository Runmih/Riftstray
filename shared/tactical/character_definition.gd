class_name TacticalCharacterDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var base_stats: Dictionary = {}
@export_range(1, 99, 1) var starting_level := 1
@export_range(1, 99, 1) var personal_level_cap := 30
@export var starting_inventory_ids: Array[StringName] = []
@export var starting_equipment_ids: Array[StringName] = []
@export var movement := 0
@export var movement_profile_id: StringName = &"ground"
@export var can_attack := true
@export var primary_weapon_id: StringName
@export var equipment_ids: Array[StringName] = []


func validation_error(ruleset: TacticalRuleset) -> String:
	if id.is_empty():
		return "Character ID is empty."
	if display_name.strip_edges().is_empty():
		return "Character %s has no display name." % id
	if starting_level < 1 or starting_level > ruleset.maximum_level:
		return "Character %s has a starting level outside the ruleset range." % id
	if personal_level_cap < starting_level or personal_level_cap > ruleset.maximum_level:
		return "Character %s has an invalid personal level cap." % id
	if movement < 0:
		return "Character %s has negative movement." % id
	if movement_profile_id.is_empty():
		return "Character %s has no movement profile." % id
	for attribute: TacticalAttributeDefinition in ruleset.attributes:
		if not base_stats.has(attribute.id) or typeof(base_stats[attribute.id]) != TYPE_INT or int(base_stats[attribute.id]) < 0:
			return "Character %s needs a nonnegative integer base value for %s." % [id, attribute.id]
	var seen_equipment: Dictionary = {}
	for equipment_id: StringName in equipment_ids:
		if seen_equipment.has(equipment_id):
			return "Character %s equips %s more than once." % [id, equipment_id]
		seen_equipment[equipment_id] = true
		if ruleset.get_weapon(equipment_id) == null:
			return "Character %s references missing equipment %s." % [id, equipment_id]
	var starting_inventory := starting_inventory_ids if not starting_inventory_ids.is_empty() else equipment_ids
	var inventory_counts: Dictionary = {}
	for equipment_id: StringName in starting_inventory:
		if ruleset.get_weapon(equipment_id) == null:
			return "Character %s starts with missing inventory %s." % [id, equipment_id]
		inventory_counts[equipment_id] = int(inventory_counts.get(equipment_id, 0)) + 1
	var starting_equipment := starting_equipment_ids if not starting_equipment_ids.is_empty() else equipment_ids
	for equipment_id: StringName in starting_equipment:
		if int(inventory_counts.get(equipment_id, 0)) <= 0:
			return "Character %s equips unowned starting item %s." % [id, equipment_id]
		inventory_counts[equipment_id] = int(inventory_counts[equipment_id]) - 1
	var primary := ruleset.get_weapon(primary_weapon_id)
	if can_attack and (primary == null or not equipment_ids.has(primary_weapon_id) or not primary.is_offensive()):
		return "Character %s needs an equipped offensive primary weapon." % id
	if not can_attack and not primary_weapon_id.is_empty():
		return "Noncombatant %s must not select a primary weapon." % id
	return ""
