extends RefCounted

func show_range(board: Control, unit: RefCounted, session: RefCounted) -> void:
	board.show_reachable(session.turns.movement.reachable(unit, session.group))

func clear(board: Control) -> void:
	board.show_reachable({})
	var empty: Array[Vector2i] = []
	board.show_path(empty)
