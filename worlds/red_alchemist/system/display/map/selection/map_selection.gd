extends RefCounted

func activate(screen: Node, cell: Vector2i) -> void:
	if screen.busy or screen.overlay.visible or screen.session.turns.current_faction() != &"player":
		return
	var clicked: RefCounted = screen.npc_group.at_cell(cell)
	if clicked != null and clicked.template.faction == &"player":
		if screen.actor == clicked:
			screen._open_actions()
		else:
			screen.actor = clicked
			resume(screen)
		return
	if screen.actor == null:
		return
	var hostile: bool = clicked != null and screen.session.hostiles(screen.actor).has(clicked.template.faction)
	if hostile or screen.mode == &"target":
		if not screen.session.permits(&"attack", screen.actor.id):
			screen._remind(&"attack", screen.actor.id)
			return
		var rows: Array[Dictionary] = screen.session.forecast(screen.actor, cell)
		if not rows.is_empty():
			screen.target_cell = cell
			screen.mode = &"forecast"
			screen._set_overlay(true)
			screen.forecast_panel.open(rows, screen.npc_group)
		return
	if clicked != null:
		return
	if not screen.session.permits(&"move", screen.actor.id):
		screen._remind(&"move", screen.actor.id)
		return
	var reachable: Dictionary = screen.session.turns.movement.reachable(screen.actor, screen.npc_group)
	if not reachable.has(cell):
		return
	screen.busy = true
	screen._lock_controls()
	await screen._move_unit(screen.actor, cell)
	screen.busy = false
	screen._lock_controls()
	if not screen._show_result():
		screen._open_actions()

func resume(screen: Node) -> void:
	if screen.actor == null or screen.actor.current_hp <= 0 or screen.actor.escaped:
		screen._clear_selection()
		return
	screen.mode = &"move"
	screen.movement_display.show_range(screen.board, screen.actor, screen.session)
	screen.board.attack_cells = screen.session.attack_cells(screen.actor)
	screen.board.queue_redraw()
	screen.board.grab_focus()
