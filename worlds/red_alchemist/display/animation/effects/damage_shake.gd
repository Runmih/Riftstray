extends RefCounted

func play(view: Control, duration: float, _direction: Vector2) -> void:
	var tween := view.create_tween()
	for offset in [Vector2(-5, 0), Vector2(5, 0), Vector2(-3, 0), Vector2.ZERO]:
		tween.tween_property(view, "visual_offset", offset, duration / 4)
	await tween.finished
	view.visual_offset = Vector2.ZERO
