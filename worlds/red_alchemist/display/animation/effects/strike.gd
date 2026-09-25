extends RefCounted

func play(view: Control, duration: float, direction: Vector2) -> void:
	var tween := view.create_tween()
	tween.tween_property(view, "visual_offset", direction * 10, duration * 0.45)
	tween.tween_property(view, "visual_offset", Vector2.ZERO, duration * 0.55)
	await tween.finished
	view.visual_offset = Vector2.ZERO
