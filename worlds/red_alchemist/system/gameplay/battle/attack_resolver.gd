extends RefCounted

const Rules = preload("res://worlds/red_alchemist/system/gameplay/battle/battle_rules.gd")
const Chances = preload("res://worlds/red_alchemist/system/gameplay/battle/chances/chance_manager.gd")
var rules := Rules.new()
var chances := Chances.new()

func resolve(step: Dictionary, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var attacker: RefCounted = step.attacker
	var defender: RefCounted = step.defender
	var events: Array[Dictionary] = []
	if attacker.current_hp <= 0 or defender.current_hp <= 0 or attacker.stunned:
		return events
	var values: Dictionary = rules.forecast(attacker, defender, step.attack)
	var reaction: bool = step.kind == &"riposte"
	var chosen: Dictionary = {"id": &"normal", "strikes": 1} if reaction else chances.choose(attacker, values.critical, rng)
	var avoided_or_blocked: bool = false
	var multiplier: float = float(chosen.get("multiplier", 3.0 if chosen.id == &"critical" else 1.0))
	var incoming_power: int = rules.damage(values.power, multiplier)
	var block_values: Dictionary = chances.block.forecast(defender, step.attack, incoming_power)
	for strike in range(int(chosen.strikes)):
		if defender.current_hp <= 0:
			break
		var hit: bool = chances.roll(values.hit, rng)
		var blocked: bool = hit and chances.roll(block_values.chance, rng)
		var overpowered: bool = blocked and block_values.overpowered
		avoided_or_blocked = avoided_or_blocked or not hit or (blocked and not overpowered)
		var before: int = defender.current_hp
		var damage: int = rules.damage(values.damage, multiplier) if hit else 0
		if blocked:
			damage = block_values.damage
		if overpowered:
			defender.stunned = true
		defender.current_hp = maxi(0, before - damage)
		events.append({"attacker": attacker.id, "defender": defender.id, "kind": step.kind, "attack_type": chosen.id, "strike": strike + 1, "hit": hit, "blocked": blocked, "overpowered": overpowered, "stunned": defender.stunned, "damage": before - defender.current_hp, "hp_before": before, "hp_after": defender.current_hp})
	if not reaction and avoided_or_blocked and defender.current_hp > 0 and not defender.stunned and attacker.current_hp > 0:
		var counter: Resource = rules.weapon(defender)
		var delta: Vector2i = attacker.cell - defender.cell
		var distance: int = absi(delta.x) + absi(delta.y)
		if counter != null and counter.area_radius == 0 and distance >= counter.minimum_range and distance <= counter.maximum_range and chances.roll(chances.riposte_chance(defender), rng):
			events.append_array(resolve({"attacker": defender, "defender": attacker, "attack": counter, "kind": &"riposte"}, rng))
	return events

