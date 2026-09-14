class_name TacticalCombatExchangeResult
extends RefCounted

var ok := false
var error := ""
var first_strike: TacticalStrikeResult
var reaction_strike: TacticalStrikeResult
var normal_counter_strike: TacticalStrikeResult
var follow_up_strike: TacticalStrikeResult
var ordered_strikes: Array[TacticalStrikeResult] = []
var events: PackedStringArray = []


func has_reaction() -> bool:
	return reaction_strike != null


func has_normal_counter() -> bool:
	return normal_counter_strike != null


func has_follow_up() -> bool:
	return follow_up_strike != null
