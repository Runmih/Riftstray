class_name TacticalEquipmentService
extends RefCounted


static func equip(
	ruleset: TacticalRuleset,
	inventory: TacticalCharacterInventory,
	instance_id: StringName,
	slot_id: StringName
) -> bool:
	inventory.last_error = ""
	var item := inventory.get_item(instance_id)
	if item == null:
		inventory.last_error = "That item is not owned."
		return false
	var definition := ruleset.get_weapon(item.definition_id)
	if definition == null:
		inventory.last_error = "Owned item %s has no authored definition." % instance_id
		return false
	if ruleset.get_equipment_slot(slot_id) == null:
		inventory.last_error = "Unknown equipment slot: %s." % slot_id
		return false
	if not definition.compatible_slots.has(slot_id):
		inventory.last_error = "%s cannot be equipped in %s." % [definition.display_name, ruleset.get_equipment_slot(slot_id).display_name]
		return false
	var occupied_slots: Array[StringName] = [slot_id]
	for reserved_slot: StringName in definition.reserved_slots:
		if ruleset.get_equipment_slot(reserved_slot) == null:
			inventory.last_error = "%s has an unknown reserved slot: %s." % [definition.display_name, reserved_slot]
			return false
		if not occupied_slots.has(reserved_slot):
			occupied_slots.append(reserved_slot)
	for occupied_slot: StringName in occupied_slots:
		var occupant := inventory.instance_in_slot(occupied_slot)
		if not occupant.is_empty() and occupant != instance_id:
			var slot := ruleset.get_equipment_slot(occupied_slot)
			inventory.last_error = "%s is occupied; unequip it first." % (slot.display_name if slot != null else String(occupied_slot))
			return false
	for existing_slot: Variant in inventory.equipped_slots:
		if inventory.instance_in_slot(StringName(existing_slot)) == instance_id and not occupied_slots.has(StringName(existing_slot)):
			inventory.last_error = "%s is already assigned to another slot." % definition.display_name
			return false
	for occupied_slot: StringName in occupied_slots:
		inventory.equipped_slots[occupied_slot] = instance_id
	return true


static func unequip(
	ruleset: TacticalRuleset,
	inventory: TacticalCharacterInventory,
	slot_id: StringName
) -> bool:
	inventory.last_error = ""
	if ruleset.get_equipment_slot(slot_id) == null:
		inventory.last_error = "Unknown equipment slot: %s." % slot_id
		return false
	var instance_id := inventory.instance_in_slot(slot_id)
	if instance_id.is_empty():
		inventory.last_error = "That slot is already empty."
		return false
	var slots_to_clear: Array[StringName] = []
	for existing_slot: Variant in inventory.equipped_slots:
		if inventory.instance_in_slot(StringName(existing_slot)) == instance_id:
			slots_to_clear.append(StringName(existing_slot))
	for existing_slot: StringName in slots_to_clear:
		inventory.equipped_slots.erase(existing_slot)
	return true
