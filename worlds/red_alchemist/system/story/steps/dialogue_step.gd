extends RefCounted

func run(context: Dictionary, step: Dictionary) -> String:
	var path: String = String(step.get("source", ""))
	if not context.dialogue.start(path):
		return context.dialogue.last_error
	await context.dialogue.finished
	return ""
