extends Resource

@export_range(1, 10) var amount: int = 1

func apply(unit: RefCounted) -> void:
	unit.extra_moves += amount

func description_for(unit: RefCounted) -> String:
	return "+%d move/turn (%d movement each) · This battle" % [amount, unit.get_movement()]
