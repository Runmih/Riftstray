class_name TacticalBuildService
extends RefCounted


static func skill_point_budget(ruleset: TacticalRuleset, level: int) -> int:
	return maxi(0, level - 1) * ruleset.skill_points_per_level


static func attribute_point_budget(ruleset: TacticalRuleset, level: int) -> int:
	return maxi(0, level - 1) * ruleset.attribute_points_per_level


static func spent_skill_points(ruleset: TacticalRuleset, build: TacticalCharacterBuild) -> int:
	var total := 0
	for skill_id: StringName in build.purchased_skill_ids:
		var skill := ruleset.get_skill(skill_id)
		if skill != null:
			total += skill.point_cost
	return total


static func spent_attribute_points(ruleset: TacticalRuleset, build: TacticalCharacterBuild) -> int:
	var total := 0
	for attribute_id: Variant in build.attribute_allocations:
		var attribute := ruleset.get_attribute(StringName(attribute_id))
		if attribute != null:
			total += int(build.attribute_allocations[attribute_id]) * attribute.point_cost
	return total


static func branch_points(ruleset: TacticalRuleset, build: TacticalCharacterBuild) -> Dictionary:
	var points: Dictionary = {}
	for skill_id: StringName in build.purchased_skill_ids:
		var skill := ruleset.get_skill(skill_id)
		if skill != null:
			points[skill.branch_id] = int(points.get(skill.branch_id, 0)) + skill.point_cost
	return points


static func validate_build(ruleset: TacticalRuleset, definition: TacticalCharacterDefinition, build: TacticalCharacterBuild) -> PackedStringArray:
	var errors := ruleset.validation_errors()
	if definition == null:
		errors.append("Character definition is missing.")
		return errors
	var definition_error := definition.validation_error(ruleset)
	if not definition_error.is_empty():
		errors.append(definition_error)
	if build == null:
		errors.append("Character build is missing.")
		return errors
	if build.character_id != definition.id:
		errors.append("Build character ID %s does not match definition %s." % [build.character_id, definition.id])
	if build.level < 1 or build.level > ruleset.maximum_level:
		errors.append("Build level must be between 1 and %d." % ruleset.maximum_level)

	var seen_skills: Dictionary = {}
	for skill_id: StringName in build.purchased_skill_ids:
		if seen_skills.has(skill_id):
			errors.append("Build purchases skill %s more than once." % skill_id)
			continue
		seen_skills[skill_id] = true
		var skill := ruleset.get_skill(skill_id)
		if skill == null:
			errors.append("Build references missing skill %s." % skill_id)
			continue
		for prerequisite: StringName in skill.prerequisites:
			if not build.purchased_skill_ids.has(prerequisite):
				errors.append("Skill %s requires %s." % [skill.id, prerequisite])
	if spent_skill_points(ruleset, build) > skill_point_budget(ruleset, build.level):
		errors.append("Build overspends its skill-point budget.")

	for allocation_id: Variant in build.attribute_allocations:
		if ruleset.get_attribute(StringName(allocation_id)) == null:
			errors.append("Build allocates unknown attribute %s." % String(allocation_id))
		elif typeof(build.attribute_allocations[allocation_id]) != TYPE_INT or int(build.attribute_allocations[allocation_id]) < 0:
			errors.append("Build has an invalid allocation for %s." % String(allocation_id))
	if spent_attribute_points(ruleset, build) > attribute_point_budget(ruleset, build.level):
		errors.append("Build overspends its attribute-point budget.")
	return errors


static func derive(ruleset: TacticalRuleset, definition: TacticalCharacterDefinition, build: TacticalCharacterBuild) -> TacticalDerivedCharacter:
	return derive_with_loadout(ruleset, definition, build, definition.equipment_ids, definition.primary_weapon_id)


static func derive_with_loadout(
	ruleset: TacticalRuleset,
	definition: TacticalCharacterDefinition,
	build: TacticalCharacterBuild,
	equipment_ids: Array[StringName],
	primary_weapon_id: StringName
) -> TacticalDerivedCharacter:
	if not validate_build(ruleset, definition, build).is_empty():
		return null
	for equipment_id: StringName in equipment_ids:
		if ruleset.get_weapon(equipment_id) == null:
			return null
	if not primary_weapon_id.is_empty() and not equipment_ids.has(primary_weapon_id):
		return null
	var derived := TacticalDerivedCharacter.new()
	derived.character_id = definition.id
	derived.display_name = definition.display_name
	derived.level = build.level
	derived.movement = definition.movement
	derived.movement_profile_id = definition.movement_profile_id
	derived.stats = definition.base_stats.duplicate(true)
	for allocation_id: Variant in build.attribute_allocations:
		var attribute := ruleset.get_attribute(StringName(allocation_id))
		derived.stats[attribute.id] = int(derived.stats[attribute.id]) + int(build.attribute_allocations[allocation_id]) * attribute.allocation_gain
	for equipment_id: StringName in equipment_ids:
		derived.equipment.append(ruleset.get_weapon(equipment_id))
	derived.primary_weapon = ruleset.get_weapon(primary_weapon_id)
	derived.effects = _ordered_effects(ruleset, build)
	for effect: TacticalEffectDefinition in derived.effects:
		if (
			effect.type == TacticalEffectDefinition.Type.STAT_MODIFIER
			and effect.stat_modifier != 0
			and _weapon_requirement_matches(effect.required_weapon_type, derived.primary_weapon)
		):
			derived.stats[effect.stat_id] = int(derived.stats.get(effect.stat_id, 0)) + effect.stat_modifier
	var selected_class := _select_class(ruleset, branch_points(ruleset, build))
	if selected_class != null:
		derived.class_id = selected_class.id
		derived.class_display_name = selected_class.display_name
		derived.class_tier = selected_class.tier
	return derived


static func _weapon_requirement_matches(required_type: StringName, weapon: TacticalWeaponDefinition) -> bool:
	return required_type.is_empty() or (weapon != null and weapon.type_id == required_type)


static func _ordered_effects(ruleset: TacticalRuleset, build: TacticalCharacterBuild) -> Array[TacticalEffectDefinition]:
	var records: Array[Dictionary] = []
	for skill_id: StringName in build.purchased_skill_ids:
		var skill := ruleset.get_skill(skill_id)
		if skill == null:
			continue
		for effect: TacticalEffectDefinition in skill.effects:
			records.append({"key": "%010d:%s:%s" % [effect.priority + 100000, skill.id, effect.id], "effect": effect})
	records.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return String(first["key"]) < String(second["key"])
	)
	var ordered: Array[TacticalEffectDefinition] = []
	for record: Dictionary in records:
		ordered.append(record["effect"] as TacticalEffectDefinition)
	return ordered


static func _select_class(ruleset: TacticalRuleset, points: Dictionary) -> TacticalClassDefinition:
	var qualified: Array[TacticalClassDefinition] = []
	for class_definition: TacticalClassDefinition in ruleset.classes:
		var qualifies := true
		for branch: Variant in class_definition.required_branch_points:
			if int(points.get(StringName(branch), 0)) < int(class_definition.required_branch_points[branch]):
				qualifies = false
				break
		if qualifies:
			qualified.append(class_definition)
	qualified.sort_custom(func(first: TacticalClassDefinition, second: TacticalClassDefinition) -> bool:
		if first.tier != second.tier:
			return first.tier > second.tier
		if first.priority != second.priority:
			return first.priority > second.priority
		return String(first.id) < String(second.id)
	)
	return qualified[0] if not qualified.is_empty() else null
