extends RefCounted

signal step_started(index: int)
const Walk = preload("res://worlds/red_alchemist/system/story/steps/walk_step.gd")
const Dialogue = preload("res://worlds/red_alchemist/system/story/steps/dialogue_step.gd")
const Pause = preload("res://worlds/red_alchemist/system/story/steps/pause_step.gd")
const Casualty = preload("res://worlds/red_alchemist/system/story/steps/casualty_step.gd")
const Reinforcement = preload("res://worlds/red_alchemist/system/story/steps/reinforcement_step.gd")
const RefreshPhase = preload("res://worlds/red_alchemist/system/story/steps/refresh_phase_step.gd")
var active: bool = false
var handlers: Dictionary = {"walk": Walk.new(), "dialogue": Dialogue.new(), "pause": Pause.new(), "casualty": Casualty.new(), "reinforcement": Reinforcement.new(), "refresh_phase": RefreshPhase.new()}

func play(path: String, context: Dictionary, start_index: int = 0) -> String:
	if active:
		return "A story scene is already playing."
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not open story scene: " + path
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return "Story scene JSON is malformed."
	var data: Dictionary = parser.data
	if not data.get("steps") is Array or data.steps.is_empty():
		return "Story scene requires at least one step."
	return await run_steps(data.steps, context, start_index)

func run_steps(steps: Array, context: Dictionary, start_index: int = 0) -> String:
	if active:
		return "A story scene is already playing."
	for step in steps:
		if not step is Dictionary or not handlers.has(step.get("type", "")):
			return "Story scene contains an unsupported step."
	if start_index < 0 or start_index >= steps.size():
		return "The saved story scene position is unavailable."
	active = true
	for index in range(start_index, steps.size()):
		step_started.emit(index)
		var step: Dictionary = steps[index]
		var error: String = await handlers[step.type].run(context, step)
		if not error.is_empty():
			active = false
			return error
	active = false
	return ""

