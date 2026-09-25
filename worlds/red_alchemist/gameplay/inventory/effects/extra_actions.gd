extends Resource

@export_range(1, 10) var amount: int = 1

func apply(unit: RefCounted) -> void:
	unit.extra_actions += amount

func description_for(_unit: RefCounted) -> String:
	return "+%d action/turn · This battle" % amount
