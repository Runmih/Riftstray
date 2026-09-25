extends RefCounted

func play(view: Control, duration: float, _direction: Vector2) -> void:
	view.tint = Color(0.5, 1.4, 1.8)
	var tween := view.create_tween()
	tween.tween_property(view, "tint", Color.WHITE, duration)
	await tween.finished
	view.tint = Color.WHITE
