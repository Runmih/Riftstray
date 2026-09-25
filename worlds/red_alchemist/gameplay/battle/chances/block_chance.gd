extends RefCounted

func profile(defender: RefCounted, attack: Resource) -> Resource:
	var shield: Resource = defender.gear.item_in_slot(&"off_hand")
	if shield == null or shield.block == null or not shield.block.damage_types.has(attack.damage_type):
		return null
	return shield.block

func forecast(defender: RefCounted, attack: Resource, incoming_power: int) -> Dictionary:
	var definition: Resource = profile(defender, attack)
	if definition == null:
		return {"chance": 0.0, "damage": 0, "overpowered": false}
	var capacity: int = maxi(0, defender.stat(definition.strength_attribute))
	return {
		"chance": clampf(definition.base_chance + float(defender.attributes.get(definition.chance_attribute, 0)) * definition.chance_per_attribute, 0, 100),
		"damage": 0,
		"overpowered": incoming_power > capacity
	}


