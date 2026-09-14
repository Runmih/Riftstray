class_name TacticalXpTransition
extends RefCounted

enum EventKind {
	FILL,
	LEVEL_UP,
	RESET,
	EXCESS,
	CAP,
}

var killer_id: StringName
var enemy_level := 1
var reward := 0
var initial_level := 1
var initial_xp_percent := 0
var personal_level_cap := 1
var final_level := 1
var final_xp_percent := 0
var is_max := false
var events: Array[Dictionary] = []


static func reward_for_enemy(killer_level: int, enemy_level_value: int) -> int:
	return clampi(30 + 3 * (enemy_level_value - killer_level), 5, 100)


func apply_award(killer: StringName, level: int, xp_percent: int, cap: int, enemy_level_value: int) -> void:
	killer_id = killer
	enemy_level = maxi(1, enemy_level_value)
	initial_level = maxi(1, level)
	initial_xp_percent = clampi(xp_percent, 0, 99)
	personal_level_cap = maxi(initial_level, cap)
	final_level = initial_level
	final_xp_percent = initial_xp_percent
	is_max = final_level >= personal_level_cap
	events.clear()
	if is_max:
		reward = 0
		final_xp_percent = 0
		events.append({"kind": EventKind.CAP, "level": final_level})
		return
	reward = reward_for_enemy(initial_level, enemy_level)

	var remaining := reward
	while remaining > 0:
		var fill_amount := mini(remaining, 100 - final_xp_percent)
		var before := final_xp_percent
		final_xp_percent += fill_amount
		remaining -= fill_amount
		events.append({"kind": EventKind.FILL, "from": before, "to": final_xp_percent, "amount": fill_amount})
		if final_xp_percent < 100:
			break
		var previous_level := final_level
		final_level += 1
		events.append({"kind": EventKind.LEVEL_UP, "from": previous_level, "to": final_level})
		final_xp_percent = 0
		events.append({"kind": EventKind.RESET, "to": 0})
		if remaining > 0:
			events.append({"kind": EventKind.EXCESS, "amount": remaining})
		if final_level >= personal_level_cap:
			is_max = true
			events.append({"kind": EventKind.CAP, "level": final_level, "discarded": remaining})
			remaining = 0
