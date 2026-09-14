extends Resource

@export var id: StringName
@export var display_name: String
@export_range(0, 30) var movement: int = 4
@export var gain_per_point: Dictionary = {}
@export var skill_family: Resource
