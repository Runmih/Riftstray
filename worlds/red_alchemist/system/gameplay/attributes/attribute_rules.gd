extends Resource

@export_range(3, 5) var points_per_level: int = 4
@export var maximum_level: int = 30
@export_range(0, 3) var npc_variation_points: int = 1
@export var labels: Dictionary = {&"max_hp": "HP", &"strength": "Strength", &"magic": "Magic", &"skill": "Skill", &"speed": "Speed", &"defense": "Defense", &"resistance": "Resistance"}
@export var gain_per_point: Dictionary = {&"max_hp": 2, &"strength": 1, &"magic": 1, &"skill": 1, &"speed": 1, &"defense": 1, &"resistance": 1}

func point_budget(level: int) -> int:
	return maxi(0, level - 1) * points_per_level

func calculate(base: Dictionary, allocations: Dictionary, class_gains: Dictionary = {}) -> Dictionary:
	var result := base.duplicate(true)
	for id in gain_per_point:
		result[id] = int(base.get(id, 0)) + int(allocations.get(id, 0)) * int(class_gains.get(id, gain_per_point[id]))
	return result

func generate_allocations(level: int, priorities: Array[StringName]) -> Dictionary:
	var allocations: Dictionary = {}
	if level < 1 or level > maximum_level or priorities.is_empty():
		return allocations
	for id in priorities:
		if not gain_per_point.has(id):
			return {}
	for point in range(point_budget(level)):
		var id: StringName = priorities[point % priorities.size()]
		allocations[id] = int(allocations.get(id, 0)) + 1
	return allocations


func generate_npc_allocations(level: int, priorities: Array[StringName]) -> Dictionary:
	var allocations := generate_allocations(level, priorities)
	if allocations.is_empty() or npc_variation_points == 0:
		return allocations
	var random := RandomNumberGenerator.new()
	random.randomize()
	var changed: Array[StringName] = []
	for _index in range(npc_variation_points):
		var targets: Array[StringName] = []
		for id in priorities:
			if not changed.has(id):
				targets.append(id)
		if targets.is_empty():
			break
		var target: StringName = targets[random.randi_range(0, targets.size() - 1)]
		var sources: Array[StringName] = []
		for id: StringName in allocations:
			if id != target and not changed.has(id) and int(allocations[id]) > 0:
				sources.append(id)
		if sources.is_empty():
			break
		var source: StringName = sources[random.randi_range(0, sources.size() - 1)]
		allocations[source] = int(allocations[source]) - 1
		allocations[target] = int(allocations.get(target, 0)) + 1
		changed.append(source)
		changed.append(target)
	return allocations
