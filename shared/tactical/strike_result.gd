class_name TacticalStrikeResult
extends RefCounted

var ok := false
var error := ""
var attacker_id: StringName
var defender_id: StringName
var is_reaction := false
var strike_kind: StringName = TacticalCombatConstants.STRIKE_INITIATING
var matchup := 0
var matchup_diagnostic := ""
var attack_power := 0
var damage_type: StringName = TacticalCombatConstants.DAMAGE_PHYSICAL
var mitigation_stat: StringName = &"defense"
var mitigation_value := 0
var hit_chance := 0
var crit_chance := 0
var block_chance := 0
var hit_roll := -1.0
var block_roll := -1.0
var crit_roll := -1.0
var hit := false
var dodged := false
var block_attempted := false
var blocked := false
var block_broken := false
var critical := false
var ordinary_damage := 0
var calculated_damage := 0
var actual_hp_lost := 0
var remaining_hp := 0
var stunned := false
var killed := false
var events: PackedStringArray = []
