extends RefCounted

signal item_used(unit_id: StringName, item_id: StringName)

func usable(unit: RefCounted, turns: RefCounted) -> Array[StringName]:
	var result: Array[StringName] = []
	if not turns.can_act(unit):
		return result
	for instance_id in unit.inventory.items:
		var item: Resource = unit.inventory.get_item(instance_id)
		if item.use_effect != null and not unit.gear.is_equipped(instance_id) and item.use_effect.available(unit, item):
			result.append(instance_id)
	return result

func use(unit: RefCounted, instance_id: StringName, turns: RefCounted) -> bool:
	var item: Resource = unit.inventory.get_item(instance_id)
	if item == null or not turns.permits(&"use_item", unit.id, item.id):
		return false
	if not usable(unit, turns).has(instance_id) or not turns.spend_action(unit):
		return false
	item.use_effect.apply(unit, item)
	unit.inventory.items.erase(instance_id)
	item_used.emit(unit.id, item.id)
	return true
