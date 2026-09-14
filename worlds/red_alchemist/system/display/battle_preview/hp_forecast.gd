extends Control

var current_hp: int = 1
var maximum_hp: int = 1
var loss: int = 0
var color: Color = Color.CORNFLOWER_BLUE

func _ready() -> void:
	custom_minimum_size = Vector2(220, 18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var maximum: float = maxf(1, maximum_hp)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.12, 0.16))
	var current_width: float = size.x * clampf(current_hp / maximum, 0, 1)
	var remaining_width: float = size.x * clampf((current_hp - loss) / maximum, 0, 1)
	draw_rect(Rect2(Vector2.ZERO, Vector2(remaining_width, size.y)), color)
	draw_rect(Rect2(Vector2(remaining_width, 0), Vector2(current_width - remaining_width, size.y)), Color.WHITE)
