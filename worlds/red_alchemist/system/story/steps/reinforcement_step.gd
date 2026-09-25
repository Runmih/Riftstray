extends RefCounted

const Reinforcement = preload("res://worlds/red_alchemist/gameplay/npc/reinforcement.gd")

func run(context: Dictionary, step: Dictionary) -> String:
	var spawn: Resource = context.spawns.get(String(step.get("placement", "")))
	if spawn == null:
		return "A reinforcement references an unknown placement."
	if context.group.get_npc(spawn.id) == null:
		if not Reinforcement.new().add_spawn(spawn, context.group, context.attribute_rules):
			return "The reinforcement placement is currently blocked."
	context.layer.refresh()
	return ""
