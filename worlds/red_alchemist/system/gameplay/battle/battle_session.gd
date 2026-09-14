extends RefCounted

const Turns = preload("res://worlds/red_alchemist/system/gameplay/battle/turns/turn_manager.gd")
const Battle = preload("res://worlds/red_alchemist/system/gameplay/battle/battle_manager.gd")
const Preview = preload("res://worlds/red_alchemist/system/gameplay/battle_preview/battle_preview.gd")
const MapInfo = preload("res://worlds/red_alchemist/system/gameplay/conditions/map_info.gd")
var turns := Turns.new()
var battle := Battle.new()
var preview := Preview.new()
var action_permission: Callable
var group: RefCounted
var win: Resource
var defeat: Resource
var outcome: StringName = &""
var escape_cells: Array[Vector2i] = []
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
	if not path.is_empty() and unit.template.tags.has(&"citizen") and escape_cells.has(unit.cell):
		unit.escaped = true
		turns.wait_unit(unit)
		group.sync_occupancy()
	return path

func attack(unit: RefCounted, center: Vector2i) -> Dictionary:
	if not permits(&"attack", unit.id):
		return {"error": "This action is currently restricted.", "events": []}
	if not outcome.is_empty():
		return {"error": "The battle has ended.", "events": []}
	var result: Dictionary = battle.execute(unit, center, group.npcs, hostiles(unit), turns)
	group.sync_occupancy()
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


func objective_text() -> String:
	var info: Dictionary = MapInfo.new().capture(group.npcs, counters)
	var lines := PackedStringArray()
	if win != null and not win.checks.is_empty():
		lines.append("Victory — " + win.describe(info))
	if defeat != null and not defeat.checks.is_empty():
		lines.append("Defeat — " + defeat.describe(info))
	return "\n".join(lines)
