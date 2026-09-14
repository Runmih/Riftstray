class_name TacticalTerrainDefinition
extends Resource

const IMPASSABLE := -1

@export var id: StringName
@export var display_name: String
@export var color := Color("2b3440")
@export var movement_costs: Dictionary = {}
@export var bonus_profiles: Array[StringName] = []
@export var occupant_hit_bonus := 0
@export var occupant_avoid_bonus := 0


func movement_cost(profile_id: StringName) -> int:
	return int(movement_costs.get(profile_id, IMPASSABLE))


func hit_bonus(profile_id: StringName) -> int:
	return occupant_hit_bonus if bonus_profiles.has(profile_id) else 0


func avoid_bonus(profile_id: StringName) -> int:
	return occupant_avoid_bonus if bonus_profiles.has(profile_id) else 0


func validation_error() -> String:
	if id.is_empty():
		return "Terrain ID is empty."
	if display_name.strip_edges().is_empty():
		return "Terrain %s has no display name." % id
	if movement_costs.is_empty():
		return "Terrain %s has no movement costs." % id
	for profile_id: Variant in movement_costs:
		if StringName(profile_id).is_empty():
			return "Terrain %s has an empty movement profile ID." % id
		if typeof(movement_costs[profile_id]) != TYPE_INT or int(movement_costs[profile_id]) == 0 or int(movement_costs[profile_id]) < IMPASSABLE:
			return "Terrain %s has invalid movement cost for %s; use -1 or a positive integer." % [id, profile_id]
	var seen: Dictionary = {}
	for profile_id: StringName in bonus_profiles:
		if profile_id.is_empty() or seen.has(profile_id):
			return "Terrain %s has an empty or duplicate bonus movement profile." % id
		seen[profile_id] = true
	return ""
