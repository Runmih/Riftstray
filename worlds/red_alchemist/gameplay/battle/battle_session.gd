extends RefCounted

signal unit_moved(unit: RefCounted)

const Turns = preload("res://worlds/red_alchemist/gameplay/battle/turns/turn_manager.gd")
const Battle = preload("res://worlds/red_alchemist/gameplay/battle/battle_manager.gd")
const Preview = preload("res://worlds/red_alchemist/gameplay/battle_preview/battle_preview.gd")
const MapInfo = preload("res://worlds/red_alchemist/gameplay/conditions/map_info.gd")
var turns := Turns.new()
var battle := Battle.new()
var preview := Preview.new()
var action_permission: Callable
var group: RefCounted
var win: Resource
var defeat: Resource
var outcome: StringName = &""
var counters: Dictionary = {}
var hostility: Dictionary = {
	&"player": [&"enemy", &"enemy_secondary"],
	&"friendly": [&"enemy", &"enemy_secondary"],
	&"ally": [&"enemy", &"enemy_secondary"],
	&"enemy": [&"player", &"friendly", &"ally"],
	&"enemy_secondary": [&"player", &"friendly", &"ally", &"enemy"]
}

func begin(npc_group: RefCounted, win_rules: Resource, defeat_rules: Resource) -> void:
	group = npc_group
	win = win_rules
	defeat = defeat_rules
	turns.phase_order = [&"player", &"friendly", &"ally", &"enemy", &"enemy_secondary"]
	turns.begin(group.npcs)

func hostiles(unit: RefCounted) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(hostility.get(unit.template.faction, []))
	return result

func move(unit: RefCounted, destination: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not permits(&"move", unit.id) or not outcome.is_empty() or not turns.can_move(unit):
		return empty
	var path: Array[Vector2i] = turns.movement.move(unit, destination, group)
	if not path.is_empty():
		notify_moved(unit)
	return path

func attack(unit: RefCounted, center: Vector2i) -> Dictionary:
	if not permits(&"attack", unit.id):
		return {"error": "This action is currently restricted.", "events": []}
	if not outcome.is_empty():
		return {"error": "The battle has ended.", "events": []}
	var result: Dictionary = battle.execute(unit, center, group.npcs, hostiles(unit), turns)
	group.sync_occupancy()
	self.result()
	return result

func forecast(unit: RefCounted, center: Vector2i) -> Array[Dictionary]:
	return preview.preview(unit, center, group.npcs, hostiles(unit), turns)

func attack_cells(unit: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	var weapon: Resource = battle.rules.weapon(unit)
	if weapon == null or not turns.can_act(unit):
		return result
	for cell: Vector2i in group.grid.tiles:
		if battle.targeting.in_range(unit.cell, cell, weapon):
			result[cell] = true
	return result

func npc_request(unit: RefCounted) -> Dictionary:
	if unit.behavior == null or unit.current_hp <= 0 or unit.escaped or unit.stunned:
		return {"type": &"wait"}
	var targets: Array = []
	for target in group.npcs:
		if target.current_hp > 0 and not target.escaped and hostiles(unit).has(target.template.faction):
			targets.append(target)
	group.sync_occupancy()
	return unit.behavior.decide(unit, group.grid, targets)

func result() -> StringName:
	if not outcome.is_empty():
		return outcome
	var info: Dictionary = MapInfo.new().capture(group.npcs, counters)
	if defeat != null and defeat.evaluate(info):
		outcome = &"defeat"
	elif win != null and win.evaluate(info):
		outcome = &"victory"
	return outcome

func permits(action: StringName, unit_id: StringName = &"", item_id: StringName = &"") -> bool:
	return not action_permission.is_valid() or bool(action_permission.call(action, unit_id, item_id))


func objective_progress() -> Dictionary:
	var info: Dictionary = MapInfo.new().capture(group.npcs, counters)
	return {"win": win.progress(info) if win != null else {}, "defeat": defeat.progress(info) if defeat != null else {}}
func notify_moved(unit: RefCounted) -> void:
	unit_moved.emit(unit)
	result()
func movement_attack_cells(unit: RefCounted, reachable: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var weapon: Resource = battle.rules.weapon(unit)
	if weapon == null or not turns.can_act(unit):
		return result
	var origins: Array = reachable.keys()
	if not origins.has(unit.cell):
		origins.append(unit.cell)
	for cell: Vector2i in group.grid.tiles:
		if reachable.has(cell) or cell == unit.cell:
			continue
		for origin: Vector2i in origins:
			if battle.targeting.in_range(origin, cell, weapon):
				result[cell] = true
				break
	return result