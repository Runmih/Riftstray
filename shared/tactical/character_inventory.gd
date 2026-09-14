class_name TacticalCharacterInventory
extends RefCounted

var owned_items: Array[TacticalOwnedItemInstance] = []
var equipped_slots: Dictionary = {}
var last_error := ""


func get_item(instance_id: StringName) -> TacticalOwnedItemInstance:
	for item: TacticalOwnedItemInstance in owned_items:
		if item.id == instance_id:
			return item
	return null


func instance_in_slot(slot_id: StringName) -> StringName:
	return StringName(equipped_slots.get(slot_id, &""))


func definition_in_slot(ruleset: TacticalRuleset, slot_id: StringName) -> TacticalWeaponDefinition:
	var item := get_item(instance_in_slot(slot_id))
	return ruleset.get_weapon(item.definition_id) if item != null else null


func equipped_definitions(ruleset: TacticalRuleset) -> Array[TacticalWeaponDefinition]:
	var result: Array[TacticalWeaponDefinition] = []
	var seen: Dictionary = {}
	for slot_id: Variant in equipped_slots:
		var instance_id := instance_in_slot(StringName(slot_id))
		if instance_id.is_empty() or seen.has(instance_id):
			continue
		seen[instance_id] = true
		var item := get_item(instance_id)
		var definition := ruleset.get_weapon(item.definition_id) if item != null else null
		if definition != null:
			result.append(definition)
	return result


func duplicate_inventory() -> TacticalCharacterInventory:
	var copy := TacticalCharacterInventory.new()
	for item: TacticalOwnedItemInstance in owned_items:
		copy.owned_items.append(item.duplicate_instance())
	copy.equipped_slots = equipped_slots.duplicate(true)
	copy.last_error = last_error
	return copy
