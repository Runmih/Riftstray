extends Resource

@export var priority: int = 0
@export_range(0, 100) var base_chance: float = 0
@export var chance_attribute: StringName = &"skill"
@export var chance_per_attribute: float = 1
@export_range(1, 10) var strikes: int = 1
@export_range(0.0, 5.0) var damage_multiplier: float = 1
