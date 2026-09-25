extends RefCounted

const Rules = preload("res://worlds/red_alchemist/gameplay/battle/battle_rules.gd")
const Chances = preload("res://worlds/red_alchemist/gameplay/battle/chances/chance_manager.gd")
const Order = preload("res://worlds/red_alchemist/gameplay/battle/exchange_order.gd")
const Targeting = preload("res://worlds/red_alchemist/gameplay/battle/targeting/targeting.gd")
var rules := Rules.new()
var chances := Chances.new()
var order := Order.new()
var targeting := Targeting.new()

func preview(attacker: RefCounted, center: Vector2i, units: Array, hostile_factions: Array[StringName], turns: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var attack: Resource = rules.weapon(attacker)
	if attack == null or not units.has(attacker) or not turns.can_act(attacker):
		return result
	for target in targeting.collect(attacker, center, units, attack, hostile_factions):
		for step: Dictionary in order.exchange(attacker, target, attack):
			if step.attacker.stunned:
				continue
			var values: Dictionary = rules.forecast(step.attacker, step.defender, step.attack)
			var outcomes: Array[Dictionary] = chances.probabilities(step.attacker, values.critical)
			for outcome: Dictionary in outcomes:
				outcome["damage_per_hit"] = rules.damage(values.damage, outcome.multiplier)
				outcome["block"] = chances.block.forecast(step.defender, step.attack, rules.damage(values.power, outcome.multiplier))
			values["riposte_chance"] = chances.riposte_chance(step.defender)
			values["block_chance"] = chances.block.forecast(step.defender, step.attack, values.power).chance
			values.merge({"attacker": step.attacker.id, "defender": step.defender.id, "kind": step.kind, "outcomes": outcomes, "requires_not_stunned": true, "requires_survival": true})
			result.append(values)
	return result



