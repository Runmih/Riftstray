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
	var scene: PackedScene = load("res://worlds/red_alchemist/display/map/map.tscn")
	if not _expect(scene != null, "Map loads"):
		return
	screen = scene.instantiate()
	root.add_child(screen)
	screen.animations.speed = 100.0
	process_frame.connect(_advance_dialogue)
	create_timer(45.0).timeout.connect(func():
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
	var starting_hp: int = unit.attributes[&"max_hp"]
	var starting_strength: int = unit.stat(&"strength")
	var starting_defense: int = unit.stat(&"defense")
	screen._choose_action(&"move")
	for index in range(20):
		await create_timer(0.01).timeout
		if not screen.busy:
			break
	if not _expect(unit.cell == before_cell and screen.mode == &"select" and not screen.overlay.visible and screen.session.turns.round_number == 1, "Browsing does not spend a turn"):
		return
	var potion_id: StringName
	for instance_id in unit.inventory.items:
		if unit.inventory.get_item(instance_id).id == &"crimson_resolve":
			potion_id = instance_id
	await screen._activate(unit.cell)
	await screen._activate(unit.cell)
	screen._choose_action(&"items")
	await screen._use_item(potion_id)
	if not _expect(unit.attributes[&"max_hp"] == maxi(1, floori(starting_hp * 0.75)) and unit.stat(&"strength") == starting_strength and unit.stat(&"defense") == starting_defense, "Potion costs HP and grants no stat buffs"):
		return
	if not _expect(screen.session.turns.actions.remaining[unit.id] == 2 and screen.session.turns.movement.remaining[unit.id] == 8, "Two action and movement allowances"):
		return
	var captured: Dictionary = screen.capture_save()
	var encoded: Variant = JSON.parse_string(JSON.stringify(captured))
	if not _expect(screen.state_codec.restore(screen.session, encoded, screen.attribute_rules), "Save/load round trip: " + screen.state_codec.last_error):
		return
	screen.layer.refresh()
	unit = screen.npc_group.get_npc(&"mihata")
	if not _expect(captured.characters.size() == 1 and captured.map_state.characters.size() == 9, "Player roster separate from all map units"):
		return
	await screen._activate(unit.cell)
	screen.npc_group.get_npc(&"assassin_2").cell = Vector2i(6, 3)
	screen.npc_group.sync_occupancy()
	screen.layer.refresh()
	await screen._activate(Vector2i(6, 4))
	screen._choose_action(&"attack")
	await screen._activate(Vector2i(6, 3))
	if not _expect(screen.mode == &"forecast" and screen.forecast_panel.visible, "Authored forecast scene opens"):
		return
	await screen._confirm_attack()
	if not _expect(screen.mode == &"move" and not screen.overlay.visible, "Attack returns to remaining movement"):
		return
	screen.state_codec.restore(screen.session, encoded, screen.attribute_rules)
	screen.layer.refresh()
	unit = screen.npc_group.get_npc(&"mihata")
	var bandage: Resource = load("res://worlds/red_alchemist/content/items/bandage.tres")
	while unit.inventory.has_space():
		unit.inventory.add_item(bandage)
	if not _expect(unit.inventory.add_item(bandage).is_empty() and not unit.gear.unequip(&"main_hand"), "Capacity blocks acquisitions and unequip"):
		return
	var overflow: Dictionary = unit.inventory.items.duplicate()
	overflow[&"mihata.item_999"] = bandage
	unit.inventory.restore_items(overflow, 1000)
	screen.item_menu.open(unit, screen.session.turns)
	if not _expect(screen.item_menu.pages.visible, "Legacy overflow is accessible"):
		return
	screen.item_menu._change_page(1)
	if not _expect(screen.item_menu.selected_item == &"mihata.item_999", "Overflow page selects preserved item"):
		return
	screen.item_menu.hide()
	screen.state_codec.restore(screen.session, encoded, screen.attribute_rules)
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
	if not _expect(spawned == 3 and screen.npc_group.npcs.size() == 12, "Exactly three reinforcements (outcome=%s, round=%d, spawned=%d, Mihata HP=%d)" % [screen.session.outcome, screen.session.turns.round_number, spawned, unit.current_hp]):
		return
	if not _expect(screen.session.outcome == &"victory", "Playable escort plan reaches victory"):
		return
	var escaped: int = 0
	for citizen in screen.npc_group.npcs:
		if citizen.escaped:
			escaped += 1
	print("ESCORT PASS: victory turn ", screen.session.turns.round_number, ", escaped ", escaped, ", three reinforcements, potion gate, independent allowances, save/load")
	var completed: Dictionary = screen.capture_save()
	if not _expect(completed.map_state == null and completed.chapter_start == null and completed.characters.size() == 1 and not completed.story.has("completed_chapters"), "Victory save drops battle and retains player progression"):
		return
	var locations = load("res://worlds/red_alchemist/system/chapter/campaign_locations.gd")
	if not _expect(locations.find(completed.story.location).get("type") == "end_of_content", "Victory routes to WIP"):
		return
	var ending = load("res://worlds/red_alchemist/display/end_of_content/end_of_content.tscn").instantiate()
	root.add_child(ending)
	ending.queue_free()
	var old: Dictionary = captured.duplicate(true)
	old.characters = old.map_state.characters.duplicate(true)
	old.map_state.erase("characters")
	old.state_version = 1
	old.story = {"chapter": "chapter1", "node": "battle", "completed_chapters": [], "flags": {}}
	var migrated: Dictionary = screen.state_codec.upgrade(JSON.parse_string(JSON.stringify(old)))
	if not _expect(migrated.characters.size() == 1 and migrated.map_state.characters.size() == 9 and migrated.story.location == "chapter1", "Legacy save migration retains every unit"):
		return
	var file = load("res://worlds/red_alchemist/system/save/save_file.gd").new("user://regression_%d.json" % Time.get_ticks_usec())
	if not _expect(file.save_data(captured), "Battle snapshot writes to disk"):
		return
	var disk: Dictionary = file.load_data()
	if not _expect(file.last_error.is_empty() and disk.map_state.units.size() == 9, "Battle snapshot reads from disk"):
		return
	if not _expect(file.delete_data(), "Temporary save cleanup"):
		return
	var entry = load("res://worlds/red_alchemist/entry.tscn").instantiate()
	root.add_child(entry)
	entry.saves.current_data = completed
	entry._open_map()
	if not _expect(entry.end_screen != null and entry.map_screen == null, "Completed save opens end screen through entry"):
		return
	entry._return_from_end()
	if not _expect(entry.end_screen == null and entry.get_node("Display").visible, "WIP returns to world menu"):
		return
	entry.queue_free()
	screen.result_dialog.hide()
	screen._retry()
	unit = screen.npc_group.get_npc(&"mihata")
	if not _expect(unit.attributes[&"max_hp"] == starting_hp and unit.extra_moves == 0 and unit.extra_actions == 0 and not screen.session.permits(&"move", unit.id), "Retry restores potion and HP cost"):
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

