extends Control

var unit: RefCounted
var displayed_hp: int
var visual_offset: Vector2 = Vector2.ZERO:
	set(value):
		visual_offset = value
		queue_redraw()
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()

func configure(character: RefCounted) -> void:
	unit = character
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_hp(unit.current_hp)

func set_hp(value: int) -> void:
	displayed_hp = value
	queue_redraw()

func _draw() -> void:
	if unit == null:
		return
	var rect := Rect2(visual_offset, size)
	var center := rect.get_center()
	draw_circle(center, size.x * 0.42, Color(0.06, 0.07, 0.09, 0.95))
	draw_arc(center, size.x * 0.42, 0, TAU, 32, unit.template.faction_color, 3, true)
	if unit.template.sprite != null:
		draw_texture_rect(unit.template.sprite, rect.grow(-size.x * 0.08), false, tint)
	var hp_rect := Rect2(rect.position + Vector2(size.x * 0.1, size.y * 0.88), Vector2(size.x * 0.8, 5))
	draw_rect(hp_rect, Color(0.12, 0.12, 0.12))
	var maximum: int = maxi(1, int(unit.attributes.get(&"max_hp", 1)))
	hp_rect.size.x *= clampf(float(displayed_hp) / maximum, 0, 1)
	draw_rect(hp_rect, unit.template.faction_color)
