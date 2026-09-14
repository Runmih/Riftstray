extends RefCounted

const Npc = preload("res://worlds/red_alchemist/system/npc/npc.gd")

func add_spawn(spawn: Resource, group: RefCounted, rules: Resource) -> bool:
	group.sync_occupancy()
	if spawn == null or group.get_npc(spawn.id) != null or not group.grid.can_enter(spawn.cell, spawn.template.movement_profile):
		return false
	group.npcs.append(Npc.new(spawn, rules))
	group.sync_occupancy()
	return true
