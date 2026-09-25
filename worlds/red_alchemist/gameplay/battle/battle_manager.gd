extends RefCounted

const Targeting = preload("res://worlds/red_alchemist/gameplay/battle/targeting/targeting.gd")
const Rules = preload("res://worlds/red_alchemist/gameplay/battle/battle_rules.gd")
const Order = preload("res://worlds/red_alchemist/gameplay/battle/exchange_order.gd")
const Resolver = preload("res://worlds/red_alchemist/gameplay/battle/attack_resolver.gd")
var targeting := Targeting.new()
var rules := Rules.new()
var order := Order.new()
var resolver := Resolver.new()
const XpManager = preload("res://worlds/red_alchemist/gameplay/progression/xp_manager.gd")
var xp := XpManager.new()
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func execute(attacker: RefCounted, center: Vector2i, units: Array, hostile_factions: Array[StringName], turns: RefCounted) -> Dictionary:
	var attack: Resource = rules.weapon(attacker)
	if attack == null or not units.has(attacker) or not turns.can_act(attacker):
		return {"error": "This character cannot attack.", "events": []}
	var targets: Array = targeting.collect(attacker, center, units, attack, hostile_factions)
	if targets.is_empty():
		return {"error": "No valid targets.", "events": []}
	turns.spend_action(attacker)
	var events: Array[Dictionary] = []
	for defender in targets:
		for step: Dictionary in order.exchange(attacker, defender, attack):
			events.append_array(resolver.resolve(step, rng))
	xp.award_kills(events, units)
	return {"error": "", "events": events}

