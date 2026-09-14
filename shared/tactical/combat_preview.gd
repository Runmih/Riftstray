class_name TacticalCombatPreview
extends RefCounted

var valid := false
var error := ""
var matchup := 0
var matchup_diagnostic := ""
var attack_power := 0
var damage_type: StringName = TacticalCombatConstants.DAMAGE_PHYSICAL
var mitigation_stat: StringName = &"defense"
var mitigation_value := 0
var hit_chance := 0
var crit_chance := 0
var block_chance := 0
var block_applicable := false
var normal_damage := 0
var block_break_damage := 0
var block_break_stuns := false
var possible_riposte := false
var attacker_equipped_weight := 0
var defender_equipped_weight := 0
var attacker_burden := 0
var defender_burden := 0
var attacker_attack_speed := 0
var defender_attack_speed := 0
