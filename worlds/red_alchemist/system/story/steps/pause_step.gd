extends RefCounted

func run(context: Dictionary, step: Dictionary) -> String:
	await context.tree.create_timer(clampf(float(step.get("seconds", 0.3)), 0.0, 30.0)).timeout
	return ""
