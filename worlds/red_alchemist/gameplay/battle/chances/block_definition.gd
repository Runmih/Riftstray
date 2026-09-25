extends Resource

@export_range(0, 100) var base_chance: float = 0
@export var chance_attribute: StringName = &"skill"
@export var chance_per_attribute: float = 1
@export var strength_attribute: StringName = &"strength"
@export var damage_types: Array[StringName] = [&"physical"]
