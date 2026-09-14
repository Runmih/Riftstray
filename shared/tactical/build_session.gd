class_name TacticalBuildSession
extends RefCounted

var ruleset: TacticalRuleset
var definition: TacticalCharacterDefinition
var build: TacticalCharacterBuild
var inventory: TacticalCharacterInventory
var last_error := ""


func _init(selected_ruleset: TacticalRuleset, character_definition: TacticalCharacterDefinition) -> void:
	ruleset = selected_ruleset
	definition = character_definition
	build = TacticalCharacterBuild.new()
	build.character_id = definition.id if definition != null else &""
	if definition != null and ruleset != null:
		build.level = clampi(definition.starting_level, 1, ruleset.maximum_level)
	inventory = TacticalCharacterInventory.new()
	_initialize_inventory()


func set_level(value: int) -> bool:
	last_error = ""
	if value < 1 or value > ruleset.maximum_level:
		last_error = "Level must stay between 1 and %d." % ruleset.maximum_level
		return false
	if TacticalBuildService.spent_skill_points(ruleset, build) > TacticalBuildService.skill_point_budget(ruleset, value):
		last_error = "Reset skills before lowering to that level."
		return false
	if TacticalBuildService.spent_attribute_points(ruleset, build) > TacticalBuildService.attribute_point_budget(ruleset, value):
		last_error = "Reset attributes before lowering to that level."
		return false
	build.level = value
	return true


func allocate_attribute(attribute_id: StringName) -> bool:
	last_error = ""
	var attribute := ruleset.get_attribute(attribute_id)
	if attribute == null:
		last_error = "Unknown attribute: %s." % attribute_id
		return false
	var remaining := TacticalBuildService.attribute_point_budget(ruleset, build.level) - TacticalBuildService.spent_attribute_points(ruleset, build)
	if remaining < attribute.point_cost:
		last_error = "Not enough attribute points."
		return false
	build.attribute_allocations[attribute_id] = int(build.attribute_allocations.get(attribute_id, 0)) + 1
	return true


func purchase_skill(skill_id: StringName) -> bool:
	last_error = ""
	var skill := ruleset.get_skill(skill_id)
	if skill == null:
		last_error = "Unknown skill: %s." % skill_id
		return false
	if build.purchased_skill_ids.has(skill_id):
		last_error = "%s is already purchased." % skill.display_name
		return false
	for prerequisite: StringName in skill.prerequisites:
		if not build.purchased_skill_ids.has(prerequisite):
			var required := ruleset.get_skill(prerequisite)
			last_error = "%s requires %s." % [skill.display_name, required.display_name if required != null else prerequisite]
			return false
	var remaining := TacticalBuildService.skill_point_budget(ruleset, build.level) - TacticalBuildService.spent_skill_points(ruleset, build)
	if remaining < skill.point_cost:
		last_error = "Not enough skill points."
		return false
	build.purchased_skill_ids.append(skill_id)
	return true


func reset_build() -> void:
	last_error = ""
	build.attribute_allocations.clear()
	build.purchased_skill_ids.clear()


func reset_skills() -> void:
	respec_skills()


func respec_skills() -> int:
	last_error = ""
	var refunded := TacticalBuildService.spent_skill_points(ruleset, build)
	build.purchased_skill_ids.clear()
	return refunded


func derive() -> TacticalDerivedCharacter:
	var errors := TacticalBuildService.validate_build(ruleset, definition, build)
	last_error = " ".join(errors)
	if not errors.is_empty():
		return null
	var equipment_ids: Array[StringName] = []
	for equipment: TacticalWeaponDefinition in inventory.equipped_definitions(ruleset):
		equipment_ids.append(equipment.id)
	var primary := inventory.definition_in_slot(ruleset, &"main_hand")
	return TacticalBuildService.derive_with_loadout(
		ruleset, definition, build, equipment_ids,
		primary.id if primary != null and primary.is_offensive() else &""
	)


func equip(instance_id: StringName, slot_id: StringName) -> bool:
	var result := TacticalEquipmentService.equip(ruleset, inventory, instance_id, slot_id)
	last_error = inventory.last_error
	return result


func unequip(slot_id: StringName) -> bool:
	var result := TacticalEquipmentService.unequip(ruleset, inventory, slot_id)
	last_error = inventory.last_error
	return result


func grant_owned_item(definition_id: StringName, instance_id: StringName) -> bool:
	last_error = ""
	if ruleset.get_weapon(definition_id) == null:
		last_error = "Cannot grant unknown item %s." % definition_id
		return false
	if instance_id.is_empty() or inventory.get_item(instance_id) != null:
		last_error = "Owned item instance ID must be nonempty and unique."
		return false
	var item := TacticalOwnedItemInstance.new()
	item.id = instance_id
	item.definition_id = definition_id
	inventory.owned_items.append(item)
	return true


func copy_build() -> TacticalCharacterBuild:
	return build.duplicate_build()


func copy_inventory() -> TacticalCharacterInventory:
	return inventory.duplicate_inventory()


func _initialize_inventory() -> void:
	if definition == null or ruleset == null:
		return
	var starting_inventory := definition.starting_inventory_ids if not definition.starting_inventory_ids.is_empty() else definition.equipment_ids
	var starting_equipment := definition.starting_equipment_ids if not definition.starting_equipment_ids.is_empty() else definition.equipment_ids
	var counts: Dictionary = {}
	var instances_by_definition: Dictionary = {}
	for equipment_id: StringName in starting_inventory:
		counts[equipment_id] = int(counts.get(equipment_id, 0)) + 1
		var instance_id := StringName("%s.%s.%d" % [definition.id, equipment_id, counts[equipment_id]])
		if not grant_owned_item(equipment_id, instance_id):
			continue
		if not instances_by_definition.has(equipment_id):
			instances_by_definition[equipment_id] = []
		instances_by_definition[equipment_id].append(instance_id)
	var equipped_counts: Dictionary = {}
	for equipment_id: StringName in starting_equipment:
		var item_index := int(equipped_counts.get(equipment_id, 0))
		var instances: Array = instances_by_definition.get(equipment_id, [])
		if item_index >= instances.size():
			continue
		var equipment := ruleset.get_weapon(equipment_id)
		if equipment != null and not equipment.compatible_slots.is_empty():
			TacticalEquipmentService.equip(ruleset, inventory, instances[item_index], equipment.compatible_slots[0])
			equipped_counts[equipment_id] = item_index + 1
