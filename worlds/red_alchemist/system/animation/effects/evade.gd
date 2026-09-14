extends RefCounted

func play(view: Control, duration: float, direction: Vector2) -> void:
	var side := Vector2(-direction.y, direction.x) * 12
	var tween := view.create_tween()
	tween.tween_property(view, "visual_offset", side, duration * 0.35)
	tween.tween_property(view, "visual_offset", Vector2.ZERO, duration * 0.65)
	await tween.finished
	view.visual_offset = Vector2.ZERO
