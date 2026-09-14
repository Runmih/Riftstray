class_name TacticalCombatExchangePreview
extends RefCounted

var valid := false
var error := ""
var initiating: TacticalCombatPreview
var riposte: TacticalCombatPreview
var normal_counter: TacticalCombatPreview
var speed_follow_up: TacticalCombatPreview
var riposte_possible := false
var normal_counter_possible := false
var speed_follow_up_possible := false
var follow_up_attacker_id: StringName
var ordered_strikes: Array[Dictionary] = []
