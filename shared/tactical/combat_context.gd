class_name TacticalCombatContext
extends RefCounted

var participants: Array[TacticalCombatantSnapshot] = []
var terminal := false


func get_combatant(combatant_id: StringName) -> TacticalCombatantSnapshot:
	for participant: TacticalCombatantSnapshot in participants:
		if participant.id == combatant_id:
			return participant
	return null


func has_adjacent_ally(combatant: TacticalCombatantSnapshot) -> bool:
	for participant: TacticalCombatantSnapshot in participants:
		if (
			participant.id != combatant.id
			and participant.is_alive_and_present()
			and participant.alliance_id == combatant.alliance_id
			and distance(participant, combatant) == 1
		):
			return true
	return false


func distance(first: TacticalCombatantSnapshot, second: TacticalCombatantSnapshot) -> int:
	return absi(first.grid_position.x - second.grid_position.x) + absi(first.grid_position.y - second.grid_position.y)
