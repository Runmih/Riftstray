extends RefCounted

func run(context: Dictionary, step: Dictionary) -> String:
	var victim: RefCounted = context.group.get_npc(StringName(step.get("character", "")))
	var attacker: RefCounted = context.group.get_npc(StringName(step.get("attacker", "")))
	if victim == null or attacker == null:
		return "A scripted casualty references a missing character."
	if victim.current_hp <= 0:
		return ""
	var before: int = victim.current_hp
	victim.current_hp = 0
	context.group.sync_occupancy()
	if context.has("evaluate_outcome"):
		context.evaluate_outcome.call()
	await context.animations.play([{"attacker": attacker.id, "defender": victim.id, "kind": &"scripted", "attack_type": &"normal", "strike": 1, "hit": true, "blocked": false, "overpowered": false, "stunned": false, "damage": before, "hp_before": before, "hp_after": 0}], context.layer, context.message)
	return ""
