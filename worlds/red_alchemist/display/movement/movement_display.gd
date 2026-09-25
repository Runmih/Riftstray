extends RefCounted

func show_range(board: Control, unit: RefCounted, session: RefCounted) -> void:
	var reachable: Dictionary = session.turns.movement.reachable(unit, session.group)
	board.show_reachable(reachable)
	board.attack_cells = session.movement_attack_cells(unit, reachable)
	board.queue_redraw()

func clear(board: Control) -> void:
	board.show_reachable({})
	board.attack_cells = {}
	var empty: Array[Vector2i] = []
	board.show_path(empty)