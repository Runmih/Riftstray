extends RefCounted

func run(context: Dictionary, _step: Dictionary) -> String:
	context.turns.refresh_phase(context.group.npcs)
	return ""