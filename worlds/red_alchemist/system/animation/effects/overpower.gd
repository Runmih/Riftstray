extends RefCounted

func play(view: Control, duration: float, direction: Vector2) -> void:
	var tween := view.create_tween()
	tween.tween_property(view, "visual_offset", direction * 18, duration * 0.3)
	tween.tween_interval(duration * 0.25)
	tween.tween_property(view, "visual_offset", Vector2.ZERO, duration * 0.45)
	await tween.finished
	view.visual_offset = Vector2.ZERO
