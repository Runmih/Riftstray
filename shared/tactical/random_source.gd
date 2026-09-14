class_name TacticalRandomSource
extends RefCounted


func roll_percent() -> float:
	return minf(randf() * 100.0, 99.999999)
