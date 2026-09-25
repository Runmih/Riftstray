extends Control

const Facing = preload("res://worlds/red_alchemist/display/npc/sprite_facing.gd")
var facing := Facing.new()
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
	facing.configure(unit.template.sprite)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_hp(unit.current_hp)

func set_hp(value: int) -> void:
	displayed_hp = value
	queue_redraw()

func _draw() -> void:
	if unit == null:
		return
	var rect := Rect2(visual_offset, size)
	var sprite: Texture2D = facing.texture()
	if sprite != null:
		draw_texture_rect(sprite, rect.grow(-size.x * 0.08), false, tint)

func face_direction(offset: Vector2, walking: bool = false) -> void:
	facing.face(offset, walking)
	queue_redraw()

func face_player() -> void:
	facing.direction = "south"
	queue_redraw()

func face_walk_direction() -> void:
	facing.direction = facing.walking_direction
	queue_redraw()