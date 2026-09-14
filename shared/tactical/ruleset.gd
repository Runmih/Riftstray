class_name TacticalRuleset
extends Resource

@export var id: StringName
@export var revision := 1
@export var maximum_level := 30
@export var skill_points_per_level := 1
@export var attribute_points_per_level := 4
@export var attack_floor := 0
@export var matchup_attack_step := 2
@export var skill_hit_coefficient := 2
@export var speed_avoid_coefficient := 2
@export var matchup_hit_step := 10
@export var block_skill_coefficient := 2
@export var strength_burden_divisor := 2
@export var speed_follow_up_threshold := 4
@export var critical_skill_divisor := 2
@export var critical_damage_multiplier := 2
@export var magic_bypasses_physical_block := true
@export var chance_minimum := 0
@export var chance_maximum := 100
@export var baseline_matchups: Array[TacticalMatchupDefinition] = []
@export var equipment_slots: Array[TacticalEquipmentSlotDefinition] = []
@export var attributes: Array[TacticalAttributeDefinition] = []
@export var weapons: Array[TacticalWeaponDefinition] = []
@export var skill_sections: Array[TacticalSkillSectionDefinition] = []
@export var skills: Array[TacticalSkillDefinition] = []
@export var classes: Array[TacticalClassDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id.is_empty():
		errors.append("Ruleset ID is empty.")
	if revision <= 0:
		errors.append("Ruleset revision must be positive.")
	if maximum_level < 1:
		errors.append("Maximum level must be at least 1.")
	if skill_points_per_level < 0 or attribute_points_per_level < 0:
		errors.append("Level point budgets cannot be negative.")
	if chance_minimum < 0 or chance_maximum > 100 or chance_minimum > chance_maximum:
		errors.append("Chance bounds must be ordered inside 0–100.")
	if attack_floor < 0 or matchup_attack_step < 0 or skill_hit_coefficient < 0 or speed_avoid_coefficient < 0 or matchup_hit_step < 0 or block_skill_coefficient < 0:
		errors.append("Combat coefficients and bounds cannot be negative.")
	if strength_burden_divisor <= 0:
		errors.append("Strength burden divisor must be positive.")
	if speed_follow_up_threshold <= 0:
		errors.append("Speed follow-up threshold must be positive.")
	if critical_skill_divisor <= 0 or critical_damage_multiplier <= 0:
		errors.append("Critical skill divisor and damage multiplier must be positive.")

	var matchup_pairs: Dictionary = {}
	for matchup: TacticalMatchupDefinition in baseline_matchups:
		if matchup == null:
			errors.append("Ruleset contains a missing baseline matchup definition.")
			continue
		var matchup_error := matchup.validation_error()
		if not matchup_error.is_empty():
			errors.append(matchup_error)
			continue
		var pair_ids := [String(matchup.attacker_weapon_type), String(matchup.defender_weapon_type)]
		pair_ids.sort()
		var pair_key := "%s\u001f%s" % pair_ids
		if matchup_pairs.has(pair_key):
			var previous := matchup_pairs[pair_key] as TacticalMatchupDefinition
			var previous_from_current_perspective := previous.value if previous.attacker_weapon_type == matchup.attacker_weapon_type else -previous.value
			if previous_from_current_perspective == matchup.value:
				errors.append("Duplicate baseline matchup relationship for %s and %s." % [matchup.attacker_weapon_type, matchup.defender_weapon_type])
			else:
				errors.append("Contradictory baseline matchup relationships for %s and %s." % [matchup.attacker_weapon_type, matchup.defender_weapon_type])
		else:
			matchup_pairs[pair_key] = matchup

	var attribute_ids: Array[StringName] = []
	var seen: Dictionary = {}
	for attribute: TacticalAttributeDefinition in attributes:
		if attribute == null:
			errors.append("Ruleset contains a missing attribute definition.")
			continue
		if seen.has(attribute.id):
			errors.append("Duplicate attribute ID: %s." % attribute.id)
		else:
			seen[attribute.id] = true
			attribute_ids.append(attribute.id)
		var error := attribute.validation_error()
		if not error.is_empty():
			errors.append(error)

	seen.clear()
	for slot_definition: TacticalEquipmentSlotDefinition in equipment_slots:
		if slot_definition == null:
			errors.append("Ruleset contains a missing equipment slot definition.")
			continue
		if seen.has(slot_definition.id):
			errors.append("Duplicate equipment slot ID: %s." % slot_definition.id)
		else:
			seen[slot_definition.id] = true
		var slot_error := slot_definition.validation_error()
		if not slot_error.is_empty():
			errors.append(slot_error)

	seen.clear()
	for weapon: TacticalWeaponDefinition in weapons:
		if weapon == null:
			errors.append("Ruleset contains a missing equipment definition.")
			continue
		if seen.has(weapon.id):
			errors.append("Duplicate equipment ID: %s." % weapon.id)
		else:
			seen[weapon.id] = true
		var error := weapon.validation_error()
		if not error.is_empty():
			errors.append(error)
		for slot_id: StringName in weapon.compatible_slots + weapon.reserved_slots:
			if get_equipment_slot(slot_id) == null:
				errors.append("Equipment %s references missing slot %s." % [weapon.id, slot_id])

	seen.clear()
	var section_orders: Dictionary = {}
	for section: TacticalSkillSectionDefinition in skill_sections:
		if section == null:
			errors.append("Ruleset contains a missing skill section definition.")
			continue
		if seen.has(section.id):
			errors.append("Duplicate skill section ID: %s." % section.id)
		else:
			seen[section.id] = true
		var section_error := section.validation_error()
		if not section_error.is_empty():
			errors.append(section_error)
		if section_orders.has(section.display_order):
			errors.append("Skill sections %s and %s share display order %d." % [section_orders[section.display_order], section.id, section.display_order])
		else:
			section_orders[section.display_order] = section.id

	seen.clear()
	var skill_slots: Dictionary = {}
	for skill: TacticalSkillDefinition in skills:
		if skill == null:
			errors.append("Ruleset contains a missing skill definition.")
			continue
		if seen.has(skill.id):
			errors.append("Duplicate skill ID: %s." % skill.id)
		else:
			seen[skill.id] = true
		var error := skill.validation_error(attribute_ids)
		if not error.is_empty():
			errors.append(error)
		if not skill.section_id.is_empty() and get_skill_section(skill.section_id) == null:
			errors.append("Skill %s references missing section %s." % [skill.id, skill.section_id])
		if not skill.section_id.is_empty():
			var skill_slot := "%s:%d" % [skill.section_id, skill.display_order]
			if skill_slots.has(skill_slot):
				errors.append("Skills %s and %s share display order %d in section %s." % [skill_slots[skill_slot], skill.id, skill.display_order, skill.section_id])
			else:
				skill_slots[skill_slot] = skill.id
	for skill: TacticalSkillDefinition in skills:
		if skill == null:
			continue
		for prerequisite: StringName in skill.prerequisites:
			if get_skill(prerequisite) == null:
				errors.append("Skill %s requires missing skill %s." % [skill.id, prerequisite])
	if _has_prerequisite_cycle():
		errors.append("Skill prerequisites contain a cycle.")

	seen.clear()
	var known_branches: Dictionary = {}
	for skill: TacticalSkillDefinition in skills:
		if skill != null and not skill.branch_id.is_empty():
			known_branches[skill.branch_id] = true
	var class_slots: Dictionary = {}
	for class_definition: TacticalClassDefinition in classes:
		if class_definition == null:
			errors.append("Ruleset contains a missing class definition.")
			continue
		if seen.has(class_definition.id):
			errors.append("Duplicate class ID: %s." % class_definition.id)
		else:
			seen[class_definition.id] = true
		var error := class_definition.validation_error()
		if not error.is_empty():
			errors.append(error)
		for branch: Variant in class_definition.required_branch_points:
			if int(class_definition.required_branch_points[branch]) > 0 and not known_branches.has(StringName(branch)):
				errors.append("Class %s requires missing skill branch %s." % [class_definition.id, branch])
		var slot := "%d:%d" % [class_definition.tier, class_definition.priority]
		if class_slots.has(slot):
			errors.append("Classes %s and %s have an ambiguous tier/priority tie." % [class_slots[slot], class_definition.id])
		else:
			class_slots[slot] = class_definition.id
	return errors


func get_attribute(attribute_id: StringName) -> TacticalAttributeDefinition:
	for attribute: TacticalAttributeDefinition in attributes:
		if attribute != null and attribute.id == attribute_id:
			return attribute
	return null


func get_weapon(weapon_id: StringName) -> TacticalWeaponDefinition:
	for weapon: TacticalWeaponDefinition in weapons:
		if weapon != null and weapon.id == weapon_id:
			return weapon
	return null


func get_equipment_slot(slot_id: StringName) -> TacticalEquipmentSlotDefinition:
	for slot_definition: TacticalEquipmentSlotDefinition in equipment_slots:
		if slot_definition != null and slot_definition.id == slot_id:
			return slot_definition
	return null


func get_skill(skill_id: StringName) -> TacticalSkillDefinition:
	for skill: TacticalSkillDefinition in skills:
		if skill != null and skill.id == skill_id:
			return skill
	return null


func get_skill_section(section_id: StringName) -> TacticalSkillSectionDefinition:
	for section: TacticalSkillSectionDefinition in skill_sections:
		if section != null and section.id == section_id:
			return section
	return null


func ordered_skill_sections() -> Array[TacticalSkillSectionDefinition]:
	var ordered := skill_sections.duplicate()
	ordered.sort_custom(func(first: TacticalSkillSectionDefinition, second: TacticalSkillSectionDefinition) -> bool:
		if first.display_order != second.display_order:
			return first.display_order < second.display_order
		return String(first.id) < String(second.id)
	)
	return ordered


func ordered_skills_in_section(section_id: StringName) -> Array[TacticalSkillDefinition]:
	var ordered: Array[TacticalSkillDefinition] = []
	for skill: TacticalSkillDefinition in skills:
		if skill != null and skill.section_id == section_id:
			ordered.append(skill)
	ordered.sort_custom(func(first: TacticalSkillDefinition, second: TacticalSkillDefinition) -> bool:
		if first.display_order != second.display_order:
			return first.display_order < second.display_order
		return String(first.id) < String(second.id)
	)
	return ordered


func get_baseline_matchup(attacker_weapon_type: StringName, defender_weapon_type: StringName) -> int:
	for matchup: TacticalMatchupDefinition in baseline_matchups:
		if matchup == null:
			continue
		if matchup.attacker_weapon_type == attacker_weapon_type and matchup.defender_weapon_type == defender_weapon_type:
			return matchup.value
		if matchup.attacker_weapon_type == defender_weapon_type and matchup.defender_weapon_type == attacker_weapon_type:
			return -matchup.value
	return 0


func _has_prerequisite_cycle() -> bool:
	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	for skill: TacticalSkillDefinition in skills:
		if skill != null and _visits_cycle(skill.id, visiting, visited):
			return true
	return false


func _visits_cycle(skill_id: StringName, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(skill_id):
		return true
	if visited.has(skill_id):
		return false
	visiting[skill_id] = true
	var skill := get_skill(skill_id)
	if skill != null:
		for prerequisite: StringName in skill.prerequisites:
			if get_skill(prerequisite) != null and _visits_cycle(prerequisite, visiting, visited):
				return true
	visiting.erase(skill_id)
	visited[skill_id] = true
	return false
