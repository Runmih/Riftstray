extends Control

@onready var flakes: CPUParticles2D = $Flakes

func _ready() -> void:
	resized.connect(_resize_emitter)
	_resize_emitter()

func _resize_emitter() -> void:
	flakes.position = Vector2(size.x * 0.5, -8.0)
	flakes.emission_rect_extents = Vector2(size.x * 0.5 + 24.0, 4.0)
	flakes.lifetime = maxf(2.0, (size.y + 32.0) / 28.0)