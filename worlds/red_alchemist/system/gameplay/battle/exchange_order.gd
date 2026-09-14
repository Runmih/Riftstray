extends RefCounted

const Rules = preload("res://worlds/red_alchemist/system/gameplay/battle/battle_rules.gd")
const Targeting = preload("res://worlds/red_alchemist/system/gameplay/battle/targeting/targeting.gd")
var rules := Rules.new()
var targeting := Targeting.new()

func exchange(attacker: RefCounted, defender: RefCounted, attack: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"attacker": attacker, "defender": defender, "attack": attack, "kind": &"initial"}]
	var counter: Resource = rules.weapon(defender)
	var can_counter: bool = attack.allows_counter and attack.area_radius == 0 and counter != null and counter.area_radius == 0
	if can_counter:
		can_counter = targeting.in_range(defender.cell, attacker.cell, counter)
	if can_counter:
		result.append({"attacker": defender, "defender": attacker, "attack": counter, "kind": &"counter"})
	var defender_speed: int = rules.speed(defender, counter) if counter != null else int(defender.attributes.get(&"speed", 0))
	var difference: int = rules.speed(attacker, attack) - defender_speed
	if difference >= Rules.FOLLOW_UP_SPEED:
		result.append({"attacker": attacker, "defender": defender, "attack": attack, "kind": &"follow_up"})
	elif can_counter and difference <= -Rules.FOLLOW_UP_SPEED:
		result.append({"attacker": defender, "defender": attacker, "attack": counter, "kind": &"follow_up"})
	return result
