extends Resource

@export var id: StringName
@export var display_name: String
@export var color := Color("2b3440")
@export var texture: Texture2D
@export var movement_costs: Dictionary = {}

func movement_cost(profile: StringName) -> int:
	var cost = movement_costs.get(profile, -1)
	return int(cost) if cost is int and cost > 0 else -1
