extends "res://worlds/red_alchemist/system/npc/behavior/behavior.gd"

@export var destination := Vector2i.ZERO

func decide(npc: RefCounted, grid: RefCounted, _targets: Array) -> Dictionary:
	if npc.cell == destination:
		return {"type": &"arrived", "destination": destination}
	return path_toward(npc, grid, destination)

