extends "res://worlds/red_alchemist/gameplay/npc/behavior/charge.gd"

@export var target_id: StringName

func decide(npc: RefCounted, grid: RefCounted, targets: Array) -> Dictionary:
	for target in targets:
		if target.id == target_id and target.current_hp > 0 and not target.escaped:
			return super.decide(npc, grid, [target])
	return super.decide(npc, grid, targets)
