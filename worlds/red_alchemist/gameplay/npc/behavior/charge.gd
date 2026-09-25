extends "res://worlds/red_alchemist/gameplay/npc/behavior/behavior.gd"

func decide(npc: RefCounted, grid: RefCounted, targets: Array) -> Dictionary:
	var close = nearest_close_target(npc, targets, 1)
	if close != null:
		return {"type": &"attack", "target_id": close.id}
	var best_path: Array[Vector2i] = []
	var best_cost := 2147483647
	for target in targets:
		if target == npc or target.current_hp <= 0:
			continue
		for offset: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var destination: Vector2i = target.cell + offset
			if not grid.can_enter(destination, npc.template.movement_profile):
				continue
			var path: Array[Vector2i] = grid.find_path(npc.cell, destination, npc.template.movement_profile)
			var cost: int = grid.path_cost(path, npc.template.movement_profile)
			if cost >= 0 and cost < best_cost:
				best_path = path
				best_cost = cost
	return movement_request(npc, grid, best_path)
