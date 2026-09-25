extends RefCounted

const XpTransition = preload("res://shared/tactical/xp_transition.gd")
var points_per_level: int = 4

func award_kills(events: Array[Dictionary], units: Array) -> void:
	var by_id: Dictionary = {}
	for unit in units:
		by_id[unit.id] = unit
	var rewarded: Dictionary = {}
	for event: Dictionary in events:
		if int(event.hp_before) <= 0 or int(event.hp_after) != 0 or rewarded.has(event.defender):
			continue
		var killer: RefCounted = by_id.get(event.attacker)
		var defeated: RefCounted = by_id.get(event.defender)
		if killer == null or defeated == null or killer.template.faction != &"player":
			continue
		rewarded[event.defender] = true
		var transition := XpTransition.new()
		transition.apply_award(killer.id, killer.level, killer.xp, killer.level_cap, defeated.level)
		var gained_levels: int = transition.final_level - killer.level
		killer.level = transition.final_level
		killer.xp = transition.final_xp_percent
		killer.unspent_attribute_points += gained_levels * points_per_level
		event["xp"] = {"amount": transition.reward, "level": killer.level, "percent": killer.xp, "levels_gained": gained_levels, "at_cap": transition.is_max}
