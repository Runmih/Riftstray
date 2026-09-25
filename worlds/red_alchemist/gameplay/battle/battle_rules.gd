extends RefCounted

const FOLLOW_UP_SPEED: int = 5

func weapon(unit: RefCounted) -> Resource:
	var item: Resource = unit.gear.item_in_slot(&"main_hand")
	return item.attack if item != null else null

func speed(unit: RefCounted, attack: Resource) -> int:
	return maxi(0, unit.stat(&"speed") - maxi(0, attack.weight))

func forecast(attacker: RefCounted, defender: RefCounted, attack: Resource) -> Dictionary:
	var offense: StringName = &"magic" if attack.damage_type == &"magical" else &"strength"
	var defense: StringName = &"resistance" if attack.damage_type == &"magical" else &"defense"
	var opposing_weapon: Resource = weapon(defender)
	var evade: int = defender.stat(&"speed")
	if opposing_weapon != null:
		evade = speed(defender, opposing_weapon)
	return {
		"power": maxi(0, attacker.stat(offense) + attack.power),
		"damage": maxi(0, attacker.stat(offense) + attack.power - defender.stat(defense)),
		"hit": clampf(attack.accuracy + 2.0 * float(attacker.attributes.get(&"skill", 0)) - 2.0 * evade, 0, 100),
		"critical": clampf(attack.critical + float(attacker.attributes.get(&"skill", 0)) * 0.5 - float(defender.attributes.get(&"skill", 0)) * 0.5, 0, 100)
	}

func damage(base_damage: int, multiplier: float) -> int:
	return maxi(0, floori(base_damage * multiplier))


