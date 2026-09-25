extends SceneTree

var screen
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	screen = load("res://worlds/red_alchemist/display/map/map.tscn").instantiate()
	root.add_child(screen)
	screen.animations.speed = 100.0
	process_frame.connect(func():
		if is_instance_valid(screen) and screen.dialogue.active:
			screen.dialogue.advance())
	for step in range(300):
		await create_timer(0.01).timeout
		if screen.story.flags.get("chapter1_opening_seen", false):
			break
	check(screen.story.flags.get("chapter1_opening_seen", false), "Opening completes")
	var unit = screen.npc_group.get_npc(&"mihata")
	var starting_hp: int = unit.current_hp
	var potion: StringName
	for key in unit.inventory.items:
		if unit.inventory.get_item(key).id == &"crimson_resolve":
			potion = key
	screen.actor = unit
	await screen._use_item(potion)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(screen.capture_save()))
	var movement: int = screen.session.turns.movement.remaining[unit.id]
	screen.actor = unit
	screen._choose_action(&"wait")
	check(screen.session.turns.actions.remaining[unit.id] == 1, "Wait spends one action")
	check(screen.session.turns.movement.remaining[unit.id] == movement and screen.mode == &"move", "Wait preserves movement and resumes selection")
	var heal_id: StringName
	for key in unit.inventory.items:
		if unit.inventory.get_item(key).id == &"healing_potion":
			heal_id = key
	unit.current_hp = 1
	check(screen.item_use.use(unit, heal_id, screen.session.turns), "Healing potion usable")
	check(unit.current_hp == mini(int(unit.attributes[&"max_hp"]), 1 + ceili(int(unit.attributes[&"max_hp"]) * 0.35)), "Potion restores 35 percent rounded up")
	check(not unit.inventory.items.has(heal_id), "Healing potion consumed")
	var effect = load("res://worlds/red_alchemist/gameplay/inventory/effects/heal_percentage.gd").new()
	unit.current_hp = int(unit.attributes[&"max_hp"])
	effect.apply(unit)
	check(unit.current_hp == int(unit.attributes[&"max_hp"]), "Healing caps at maximum")
	check(screen.state_codec.restore(screen.session, snapshot, screen.attribute_rules), "Snapshot restores")
	screen.layer.refresh()
	unit = screen.npc_group.get_npc(&"mihata")
	var male = screen.npc_group.get_npc(&"assassin_1")
	var female = screen.npc_group.get_npc(&"assassin_2")
	check(male.gender == &"male" and female.gender == &"female", "Saved NPC genders preserved")
	check(male.template.display_name == "Assassin" and female.template.display_name == "Assassin", "Saved authored names preserved")
	check(male.template.id == &"kharazad_fighter" and female.template.id == &"kharazad_fighter", "Pursuers are fighters")
	check(male.template.sprite.resource_path.contains("sprite_male") and female.template.sprite.resource_path.contains("sprite_female"), "Independent gender sprite variants")
	check(load(male.template_path).display_name == "Kharazad Fighter", "Shared template remains unchanged")
	var view = screen.layer.get_view(unit.id)
	var other = screen.layer.get_view(male.id)
	view.face_direction(Vector2.LEFT, true)
	view.face_player()
	check(view.facing.direction == "south", "Selection faces player")
	view.face_walk_direction()
	check(view.facing.direction == "west" and other.facing.direction == "south", "Facing and remembered walking are per unit")
	for name in ["north", "south", "east", "west"]:
		check(view.facing.textures.has(name), "Directional sprite exists: " + name)
	var area: Rect2 = screen.board._geometry()
	var image_area: Rect2 = screen.board.visual_rect()
	check(area.size.is_equal_approx(image_area.size * Vector2(0.75, 0.625)), "Playable area matches image padding")
	check(screen.board.cell_rect(Vector2i(15, 9)).end.is_equal_approx(area.end), "Grid aligns to playable boundary")
	var selected: Vector2i = screen.board.selected
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(1, 1)
	screen.board._gui_input(click)
	check(screen.board.selected == selected, "Padding click does not select a cell")
	var board = load("res://worlds/red_alchemist/display/map/board.gd").new()
	root.add_child(board)
	board.configure(screen.grid, "res://missing_chapter")
	check(board.map_visual == null, "Missing map image falls back safely")
	board.queue_free()
	check(load("res://worlds/red_alchemist/gameplay/map/terrain/snow.tres").movement_cost(&"ground") == 2, "Snow costs two movement")
	var file = load("res://worlds/red_alchemist/system/save/save_file.gd").new("user://regression_%d.json" % Time.get_ticks_usec())
	check(file.save_data(snapshot), "Temporary save writes")
	check(file.load_data().map_state.characters.size() == 9, "Temporary save reads all units")
	check(file.delete_data(), "Temporary save removed")
	for npc in screen.npc_group.npcs:
		if npc.current_hp > 0 and npc.template.tags.has(&"citizen"):
			npc.escaped = true
	check(screen.session.result() == &"victory", "All remaining citizens escaped triggers victory")
	var completed: Dictionary = screen.capture_save()
	check(completed.map_state == null and completed.chapter_start == null, "Victory clears map snapshot")
	var entry = load("res://worlds/red_alchemist/entry.tscn").instantiate()
	root.add_child(entry)
	entry.saves.current_data = completed
	entry._open_map()
	check(entry.end_screen != null, "Completed save routes to ending")
	entry._return_from_end()
	check(entry.end_screen == null and entry.get_node("Display").visible, "Ending returns to menu")
	entry.queue_free()
	screen._retry()
	unit = screen.npc_group.get_npc(&"mihata")
	check(unit.current_hp == starting_hp and unit.extra_moves == 0, "Retry restores entry HP and allowances")
	screen.queue_free()
	await process_frame
	print("RECENT CHANGES: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)