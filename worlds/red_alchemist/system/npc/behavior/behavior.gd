extends Resource

func decide(_npc: RefCounted, _grid: RefCounted, _targets: Array) -> Dictionary:
	return {"type": &"wait"}

func path_toward(npc: RefCounted, grid: RefCounted, destination: Vector2i) -> Dictionary:
	var path: Array[Vector2i] = grid.find_path(npc.cell, destination, npc.template.movement_profile)
	return movement_request(npc, grid, path)

func movement_request(npc: RefCounted, grid: RefCounted, path: Array[Vector2i]) -> Dictionary:
	if path.size() < 2:
		return {"type": &"wait"}
	var steps: Array[Vector2i] = [npc.cell]
	var remaining: int = npc.get_movement()
	for index in range(1, path.size()):
		var cost: int = grid.movement_cost(path[index], npc.template.movement_profile)
		if cost < 1 or cost > remaining:
			break
		remaining -= cost
		steps.append(path[index])
	return {"type": &"move", "destination": steps.back(), "path": steps} if steps.size() > 1 else {"type": &"wait"}

func nearest_close_target(npc: RefCounted, targets: Array, distance: int):
	var closest = null
	var best := distance + 1
	for target in targets:
		if target == npc or target.current_hp <= 0:
			continue
		var delta: Vector2i = target.cell - npc.cell
		var separation := absi(delta.x) + absi(delta.y)
		if separation <= distance and separation < best:
			closest = target
			best = separation
	return closest


