class_name TacticalSeededRandomSource
extends TacticalRandomSource

var _random := RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	_random.seed = seed_value


func roll_percent() -> float:
	return minf(_random.randf() * 100.0, 99.999999)
