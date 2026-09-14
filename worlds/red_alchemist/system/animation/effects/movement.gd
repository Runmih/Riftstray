extends RefCounted

func play(view: Control, board: Control, path: Array[Vector2i], duration: float) -> void:
	if path.size() < 2:
		return
	view.position = board.cell_rect(path[0]).position
	var tween := view.create_tween()
	for index in range(1, path.size()):
		tween.tween_property(view, "position", board.cell_rect(path[index]).position, duration)
		tween.parallel().tween_method(func(progress: float): view.visual_offset = Vector2(0, -sin(progress * PI) * 3), 0.0, 1.0, duration)
	await tween.finished
	view.visual_offset = Vector2.ZERO
	view.position = board.cell_rect(path.back()).position
