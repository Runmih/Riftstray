extends RefCounted

const GearDefinition = preload("res://worlds/red_alchemist/system/gameplay/gear/gear_definition.gd")
var slot_names: Dictionary = {&"main_hand": "Main Hand", &"off_hand": "Off Hand", &"body": "Body"}
var equipped: Dictionary = {}
var last_error := ""
var inventory: RefCounted

func _init(owned_inventory: RefCounted) -> void:
	inventory = owned_inventory

func equip(instance_id: StringName, slot: StringName) -> bool:
	last_error = ""
	var item: Resource = inventory.get_item(instance_id)
	if not item is GearDefinition or not slot_names.has(slot) or not item.compatible_slots.has(slot):
		last_error = "This item cannot be equipped in that slot."
		return false
	var required: Array[StringName] = [slot]
	for reserved: StringName in item.reserved_slots:
		if not required.has(reserved):
			required.append(reserved)
	for target in required:
		if not slot_names.has(target) or (equipped.has(target) and equipped[target] != instance_id):
			last_error = "A required equipment slot is unavailable."
			return false
	for existing in equipped:
		if equipped[existing] == instance_id and not required.has(existing):
			last_error = "This item is already equipped elsewhere."
			return false
	for target in required:
		equipped[target] = instance_id
	return true

func unequip(slot: StringName) -> bool:
	last_error = ""
	if not equipped.has(slot):
		last_error = "This slot is empty."
		return false
	var instance_id: StringName = equipped[slot]
	for existing in equipped.keys():
		if equipped[existing] == instance_id:
			equipped.erase(existing)
	return true

func is_equipped(instance_id: StringName) -> bool:
	return equipped.values().has(instance_id)

func item_in_slot(slot: StringName) -> Resource:
	return inventory.get_item(equipped.get(slot, &""))
