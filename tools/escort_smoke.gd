extends SceneTree

var screen
var failed: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> bool:
	if not condition:
		failed = true
		push_error(label)
		quit(1)
	return condition

func _run() -> void:
	var scene: PackedScene = load("res://worlds/red_alchemist/system/display/map/map.tscn")
	if not _expect(scene != null, "Map loads"):
		return
	screen = scene.instantiate()
	root.add_child(screen)
	screen.animations.speed = 100.0
	process_frame.connect(_advance_dialogue)
	create_timer(30.0).timeout.connect(func():
		push_error("Escort test timed out")
		quit(1))
	for index in range(300):
		await create_timer(0.01).timeout
		if screen.story.flags.get("chapter1_opening_seen", false):
			break
	if not _expect(screen.story.flags.get("chapter1_opening_seen", false), "Opening finishes"):
		return
	if not _expect(screen.npc_group.get_npc(&"courtesan_6").current_hp == 0, "Exactly the authored casualty occurs"):
		return
	if not _expect(screen.npc_group.npcs.size() == 9, "Initial cast is Mihata, six courtesans and two enemies"):
		return
	var unit = screen.npc_group.get_npc(&"mihata")
	var before_cell: Vector2i = unit.cell
	screen._choose_action(&"move")
	for index in range(20):
		await create_timer(0.01).timeout
		if not screen.busy:
			break
	if not _expect(unit.cell == before_cell and screen.mode == &"select" and not screen.overlay.visible and screen.session.turns.round_number == 1, "Other choices show the potion reminder without spending a turn"):
		return
	var potion_id: StringName
	for instance_id in unit.inventory.items:
		if unit.inventory.get_item(instance_id).id == &"crimson_resolve":
			potion_id = instance_id
	await screen._activate(unit.cell)
	await screen._activate(unit.cell)
	screen._choose_action(&"items")
	await screen._use_item(potion_id)
	if not _expect(unit.attributes[&"max_hp"] == 81 and unit.stat(&"strength") == 14 and unit.stat(&"defense") == 18, "Potion costs HP and grants no stat buffs"):
		return
	if not _expect(screen.session.turns.actions.remaining[unit.id] == 2 and screen.session.turns.movement.remaining[unit.id] == 8, "Two action and movement allowances"):
		return
	var captured: Dictionary = screen.capture_save()
	var encoded: Variant = JSON.parse_string(JSON.stringify(captured))
	if not _expect(screen.state_codec.restore(screen.session, encoded, screen.attribute_rules), "Save/load round trip: " + screen.state_codec.last_error):
		return
	screen.layer.refresh()
	unit = screen.npc_group.get_npc(&"mihata")
	var first: Array[Vector2i] = screen.session.move(unit, Vector2i(6, 4))
	if not _expect(not first.is_empty() and screen.session.turns.movement.remaining[unit.id] == 4 and screen.session.turns.actions.remaining[unit.id] == 2, "First move spends one movement allowance only"):
		return
	var second: Array[Vector2i] = screen.session.move(unit, Vector2i(6, 3))
	if not _expect(not second.is_empty() and not screen.session.turns.can_move(unit) and screen.session.turns.can_act(unit), "Second move leaves actions available"):
		return
	screen.state_codec.restore(screen.session, encoded, screen.attribute_rules)
	screen.layer.refresh()
	for turn in range(12):
		unit = screen.npc_group.get_npc(&"mihata")
		_player_turn(unit)
		screen.layer.refresh()
		await screen._end_turn()
		if not screen.session.outcome.is_empty():
			break
	var spawned: int = 0
	for key in screen.session.counters:
		if String(key).begins_with("reinforcement_"):
			spawned += int(screen.session.counters[key])
	if not _expect(spawned == 3 and screen.npc_group.npcs.size() == 12, "Exactly three reinforcements"):
		return
	if not _expect(screen.session.outcome == &"victory", "Playable escort plan reaches victory"):
		return
	var escaped: int = 0
	for citizen in screen.npc_group.npcs:
		if citizen.escaped:
			escaped += 1
	print("ESCORT PASS: victory turn ", screen.session.turns.round_number, ", escaped ", escaped, ", three reinforcements, potion gate, independent allowances, save/load")
	screen.result_dialog.hide()
	screen._retry()
	unit = screen.npc_group.get_npc(&"mihata")
	if not _expect(unit.attributes[&"max_hp"] == 108 and unit.extra_moves == 0 and unit.extra_actions == 0 and screen.session.potion_required(), "Retry restores potion and HP cost"):
		return
	screen.queue_free()
	await process_frame
	quit(0)

func _advance_dialogue() -> void:
	if is_instance_valid(screen) and screen.dialogue.active:
		screen.dialogue.advance()

func _player_turn(unit: RefCounted) -> void:
	for attempt in range(6):
		var target = _most_threatening_enemy(unit)
		if target == null:
			return
		var weapon: Resource = screen.session.battle.rules.weapon(unit)
		if screen.session.turns.can_act(unit) and screen.session.battle.targeting.in_range(unit.cell, target.cell, weapon):
			var forecast: Array[Dictionary] = screen.session.forecast(unit, target.cell)
			if not _expect(not forecast.is_empty(), "Forecast available before attack"):
				return
			screen.session.attack(unit, target.cell)
			continue
		if not screen.session.turns.can_move(unit):
			return
		var reachable: Dictionary = screen.session.turns.movement.reachable(unit, screen.npc_group)
		var best: Vector2i = unit.cell
		var best_distance: int = 10000
		var best_cost: int = 10000
		for cell: Vector2i in reachable:
			var distance: int = absi(cell.x - target.cell.x) + absi(cell.y - target.cell.y)
			if distance < best_distance or (distance == best_distance and int(reachable[cell]) < best_cost):
				best = cell
				best_distance = distance
				best_cost = int(reachable[cell])
		if best == unit.cell:
			return
		screen.session.move(unit, best)

func _most_threatening_enemy(unit: RefCounted):
	var best = null
	var score: float = INF
	for enemy in screen.npc_group.npcs:
		if enemy.template.faction != &"enemy" or enemy.current_hp <= 0:
			continue
		var distance: int = 10000
		for citizen in screen.npc_group.npcs:
			if citizen.template.tags.has(&"citizen") and citizen.current_hp > 0 and not citizen.escaped:
				distance = mini(distance, absi(enemy.cell.x - citizen.cell.x) + absi(enemy.cell.y - citizen.cell.y))
		var candidate: float = distance + 0.01 * (absi(enemy.cell.x - unit.cell.x) + absi(enemy.cell.y - unit.cell.y))
		if candidate < score:
			score = candidate
			best = enemy
	return best

