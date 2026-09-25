extends "res://worlds/red_alchemist/gameplay/npc/behavior/behavior.gd"

func decide(_npc: RefCounted, _grid: RefCounted, _targets: Array) -> Dictionary:
	return {"type": &"wait"}
