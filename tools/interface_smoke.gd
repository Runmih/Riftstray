extends SceneTree

var screen
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	root.size = Vector2i(1152, 648)
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
	var moves: int = screen.session.turns.movement.remaining[unit.id]
	screen._show_character(unit.cell)
	var reach: Dictionary = screen.session.turns.movement.reachable(unit, screen.npc_group)
	check(not screen.board._reachable.is_empty(), "Hover shows movement")
	check(not screen.board.attack_cells.is_empty(), "Hover shows attack extension")
	var distant: bool = false
	for cell: Vector2i in screen.board.attack_cells:
		check(not reach.has(cell), "Attack extension does not cover movement cells")
		if absi(cell.x - unit.cell.x) + absi(cell.y - unit.cell.y) > 1:
			distant = true
	check(distant, "Attack extension reaches beyond current weapon range")
	await screen._activate(unit.cell)
	check(screen.mode == &"move" and not screen.overlay.visible, "First selection prioritizes movement")
	await screen._activate(unit.cell)
	check(screen.action_menu.visible and not screen.dialogue.active, "Second confirmation opens menu without reminder")
	screen._choose_action(&"move")
	check(not screen.dialogue.active and screen.session.turns.movement.remaining[unit.id] == moves, "Opening Move does not spend movement or remind")
	screen._cancel()
	await screen._activate(Vector2i(0, 5))
	check(screen.action_menu.visible and not screen.action_menu.buttons[&"attack"].visible, "Empty tile opens limited menu")
	screen._cancel()
	await screen._activate(unit.cell)
	screen._open_actions()
	screen._choose_action(&"attack")
	check(not screen.dialogue.active, "Attack targeting can be inspected without reminder")
	screen._cancel()
	check(not screen.dialogue.active, "Cancel does not remind")
	check(screen.selection.choose(Vector2i(6, 4), screen.session, unit, false).get("type") == &"restricted", "Committing reachable move is gated")
	check(screen.selection.choose(Vector2i(15, 9), screen.session, unit, false).get("type") == &"context", "Distant empty click is not gated")
	check(not screen.session.permits(&"wait", unit.id) and not screen.session.permits(&"attack", unit.id), "Wait and committed attack are gated")
	check(screen.session.permits(&"move", &"other_player"), "Restriction applies only to authored unit")
	check(screen.session.permits(&"cancel", unit.id), "Cancel permitted")
	var potion: StringName
	for id in unit.inventory.items:
		if unit.inventory.get_item(id).id == &"crimson_resolve":
			potion = id
	screen.actor = unit
	await screen._use_item(potion)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(screen.capture_save()))
	await screen._activate(unit.cell)
	await screen._activate(Vector2i(6, 4))
	check(unit.cell == Vector2i(6, 4) and screen.action_menu.visible, "Movement commits then opens context menu")
	screen._cancel()
	screen.session.turns.actions.finish(unit.id)
	screen.session.turns.movement.finish(unit.id)
	screen._open_actions()
	check(not screen.action_menu.buttons[&"move"].visible and screen.action_menu.buttons[&"save"].visible, "Spent character opens limited menu")
	screen._cancel()
	check(screen.state_codec.restore(screen.session, saved, screen.attribute_rules), "Restore after interaction tests")
	screen.layer.refresh()
	unit = screen.npc_group.get_npc(&"mihata")
	screen.actor = unit
	screen._choose_action(&"items")
	var menu = screen.item_menu
	var selected: StringName = menu.selected_item
	var heal_index: int = -1
	for index in range(menu._ids.size()):
		if unit.inventory.get_item(menu._ids[index]).id == &"healing_potion":
			heal_index = index
	check(heal_index >= 0, "Healing potion present")
	menu.slots.get_child(heal_index).mouse_entered.emit()
	check(menu.selected_item == selected and menu.item_name.text == "Healing Potion", "Hover previews without selecting")
	menu.slots.get_child(heal_index).mouse_exited.emit()
	check(menu.item_name.text == unit.inventory.get_item(selected).display_name, "Leaving hover restores selected details")
	menu._activate_slot(heal_index)
	check(menu.selected_item == menu._ids[heal_index], "Click selects item")
	check(menu.description.text.count("35%") == 1, "Healing description has no duplicated effect")
	unit.current_hp = 1
	var actions: int = screen.session.turns.actions.remaining[unit.id]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.double_click = true
	menu._slot_input(click, heal_index)
	await process_frame
	await process_frame
	check(unit.current_hp > 1 and screen.session.turns.actions.remaining[unit.id] == actions - 1, "Double click uses exactly one action and heals")
	check(not screen.overlay.visible, "Used item closes inventory")
	check(screen.get_node("Interface/WinPanel/Text").text.contains("Get all surviving"), "Victory panel uses readable instructions")
	check(screen.get_node("Interface/DefeatPanel/Text").text.contains("dies") and not screen.get_node("Interface/DefeatPanel/Text").text.contains("need"), "Defeat panel describes failure rather than a target")
	for dimensions: Vector2i in [Vector2i(1152, 648), Vector2i(900, 560)]:
		root.size = dimensions
		await process_frame
		await process_frame
		screen.actor = unit
		screen._open_actions()
		await process_frame
		check(root.get_visible_rect().encloses(screen.action_menu.get_global_rect()), "Context menu fits " + str(dimensions))
		screen._choose_action(&"items")
		await process_frame
		check(root.get_visible_rect().encloses(menu.get_global_rect()), "Inventory fits " + str(dimensions))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("C:/Users/fprud/Documents/ChatGPT/Riftstray/interface_%dx%d.png" % [dimensions.x, dimensions.y])
		screen._cancel()
		screen._cancel()
	screen.queue_free()
	await process_frame
	print("INTERFACE: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)