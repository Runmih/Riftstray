extends "res://worlds/red_alchemist/gameplay/npc/behavior/behavior.gd"

@export_range(1, 20) var distance: int = 1

func decide(npc: RefCounted, _grid: RefCounted, targets: Array) -> Dictionary:
	var target = nearest_close_target(npc, targets, distance)
	return {"type": &"attack", "target_id": target.id} if target != null else {"type": &"wait"}
