extends RefCounted

const BlockChance = preload("res://worlds/red_alchemist/system/gameplay/battle/chances/block_chance.gd")
var block := BlockChance.new()

func rates(character: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill: Resource in character.skills.active_skills():
		var effect: Resource = skill.attack_effect
		if effect == null:
			continue
		var chance: float = clampf(effect.base_chance + float(character.attributes.get(effect.chance_attribute, 0)) * effect.chance_per_attribute, 0, 100)
		result.append({"id": skill.id, "priority": effect.priority, "chance": chance, "strikes": effect.strikes, "multiplier": effect.damage_multiplier})
	result.sort_custom(func(a: Dictionary, b: Dictionary):
		if a.priority == b.priority:
			return String(a.id) < String(b.id)
		return a.priority > b.priority)
	return result

func probabilities(character: RefCounted, critical: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var remaining: float = 1
	for skill: Dictionary in rates(character):
		var entry: Dictionary = skill.duplicate()
		entry["probability"] = remaining * skill.chance / 100.0
		remaining *= 1.0 - skill.chance / 100.0
		result.append(entry)
	result.append({"id": &"critical", "probability": remaining * critical / 100.0, "strikes": 1, "multiplier": 3.0})
	result.append({"id": &"normal", "probability": remaining * (1.0 - critical / 100.0), "strikes": 1, "multiplier": 1.0})
	return result

func roll(percent: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() * 100.0 < clampf(percent, 0, 100)

func choose(character: RefCounted, critical: float, rng: RandomNumberGenerator) -> Dictionary:
	for skill: Dictionary in rates(character):
		if roll(skill.chance, rng):
			return skill
	return {"id": &"critical" if roll(critical, rng) else &"normal", "strikes": 1}


func riposte_chance(unit: RefCounted) -> float:
	var best: float = 0
	for skill: Resource in unit.skills.active_skills():
		var effect: Resource = skill.riposte_effect
		if effect != null:
			best = maxf(best, effect.base_chance + float(unit.attributes.get(effect.chance_attribute, 0)) * effect.chance_per_attribute)
	return clampf(best, 0, 100)
