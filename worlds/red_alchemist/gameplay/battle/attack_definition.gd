extends Resource

@export var damage_type: StringName = &"physical"
@export var power: int = 0
@export_range(0, 100) var accuracy: float = 90
@export_range(0, 100) var critical: float = 0
@export var weight: int = 0
@export_range(1, 20) var minimum_range: int = 1
@export_range(1, 20) var maximum_range: int = 1
@export_range(0, 20) var area_radius: int = 0
@export var allows_counter: bool = true
