extends RefCounted

const DIRECTIONS = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const INVALID_CELL = Vector2i(-1, -1)

var width := 0
var height := 0
var tiles: Dictionary = {}
var blocked: Dictionary = {}

func _init(definition: Resource) -> void:
	var catalog: Dictionary = {}
	for terrain in definition.terrains:
		catalog[terrain.id] = terrain
	height = definition.rows.size()
	for y in range(height):
		var row: PackedStringArray = definition.rows[y].split(",", true)
		width = maxi(width, row.size())
		for x in range(row.size()):
			var id := StringName(row[x].strip_edges())
			if catalog.has(id):
				tiles[Vector2i(x, y)] = catalog[id]

func terrain_at(cell: Vector2i) -> Resource:
	return tiles.get(cell)

func contains(cell: Vector2i) -> bool:
	return tiles.has(cell)

func set_blocked_cells(cells: Array[Vector2i]) -> void:
	blocked.clear()
	for cell in cells:
		blocked[cell] = true

func movement_cost(cell: Vector2i, profile: StringName) -> int:
	var terrain := terrain_at(cell)
	return terrain.movement_cost(profile) if terrain != null else -1

func can_enter(cell: Vector2i, profile: StringName) -> bool:
	return movement_cost(cell, profile) > 0 and not blocked.has(cell)

func reachable_cells(start: Vector2i, budget: int, profile: StringName = &"ground") -> Dictionary:
	if budget < 0:
		return {}
	return _search(start, INVALID_CELL, profile, budget)["costs"]

func find_path(start: Vector2i, goal: Vector2i, profile: StringName = &"ground", budget: int = -1) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not contains(goal):
		return path
	var search := _search(start, goal, profile, budget)
	if not search["costs"].has(goal):
		return path
	var step := goal
	path.append(step)
	while step != start:
		step = search["previous"][step]
		path.push_front(step)
	return path

func path_cost(path: Array[Vector2i], profile: StringName = &"ground") -> int:
	if path.is_empty() or movement_cost(path[0], profile) < 1:
		return -1
	var cost := 0
	for index in range(1, path.size()):
		var delta := path[index] - path[index - 1]
		if absi(delta.x) + absi(delta.y) != 1 or not can_enter(path[index], profile):
			return -1
		cost += movement_cost(path[index], profile)
	return cost

func _search(start: Vector2i, goal: Vector2i, profile: StringName, budget: int) -> Dictionary:
	var costs: Dictionary = {}
	var previous: Dictionary = {}
	if movement_cost(start, profile) < 1:
		return {"costs": costs, "previous": previous}
	var frontier: Array[Vector2i] = [start]
	costs[start] = 0
	previous[start] = start
	while not frontier.is_empty():
		var best_index := 0
		for index in range(1, frontier.size()):
			var candidate := frontier[index]
			var best := frontier[best_index]
			if costs[candidate] < costs[best] or (costs[candidate] == costs[best] and (candidate.y < best.y or (candidate.y == best.y and candidate.x < best.x))):
				best_index = index
		var current: Vector2i = frontier.pop_at(best_index)
		if current == goal:
			break
		for direction: Vector2i in DIRECTIONS:
			var neighbor := current + direction
			if not can_enter(neighbor, profile):
				continue
			var next_cost: int = costs[current] + movement_cost(neighbor, profile)
			if budget >= 0 and next_cost > budget:
				continue
			if not costs.has(neighbor) or next_cost < costs[neighbor]:
				costs[neighbor] = next_cost
				previous[neighbor] = current
				if not frontier.has(neighbor):
					frontier.append(neighbor)
	return {"costs": costs, "previous": previous}
