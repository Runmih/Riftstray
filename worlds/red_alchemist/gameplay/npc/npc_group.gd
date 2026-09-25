extends RefCounted

const Character = preload("res://worlds/red_alchemist/gameplay/character/character.gd")
const Npc = preload("res://worlds/red_alchemist/gameplay/npc/npc.gd")
var npcs: Array = []
var grid: RefCounted

func _init(spawns: Array[Resource], rules: Resource, map_grid: RefCounted) -> void:
	grid = map_grid
	for spawn in spawns:
		if spawn == null or spawn.template == null or spawn.id.is_empty():
			continue
		if get_npc(spawn.id) != null or at_cell(spawn.cell) != null or not grid.can_enter(spawn.cell, spawn.template.movement_profile):
			continue
		npcs.append(Character.new(spawn, rules) if spawn.template.is_named else Npc.new(spawn, rules))
	sync_occupancy()

func get_npc(id: StringName):
	for npc in npcs:
		if npc.id == id:
			return npc
	return null

func at_cell(cell: Vector2i):
	for npc in npcs:
		if npc.cell == cell and npc.current_hp > 0 and not npc.escaped:
			return npc
	return null

func assign_behavior(id: StringName, behavior: Resource) -> void:
	var npc = get_npc(id)
	if npc != null:
		npc.behavior = behavior.duplicate(true) if behavior != null else null

func plan_action(id: StringName, target_ids: Array[StringName]) -> Dictionary:
	var npc = get_npc(id)
	if npc == null or npc.current_hp <= 0 or npc.behavior == null:
		return {"type": &"wait"}
	var targets: Array = []
	for target_id in target_ids:
		var target = get_npc(target_id)
		if target != null and target != npc and target.current_hp > 0 and not target.escaped and target.template.faction != npc.template.faction:
			targets.append(target)
	sync_occupancy()
	return npc.behavior.decide(npc, grid, targets)

func sync_occupancy() -> void:
	var cells: Array[Vector2i] = []
	for npc in npcs:
		if npc.current_hp > 0 and not npc.escaped:
			cells.append(npc.cell)
	grid.set_blocked_cells(cells)




