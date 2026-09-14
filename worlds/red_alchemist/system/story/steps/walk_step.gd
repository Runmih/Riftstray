extends RefCounted

func run(context: Dictionary, step: Dictionary) -> String:
	var unit: RefCounted = context.group.get_npc(StringName(step.get("character", "")))
	if unit == null or unit.current_hp <= 0 or unit.escaped:
		return "Story walk requires an active character."
	if not step.get("to") is Array or step.to.size() != 2:
		return "Story walk requires a destination [x, y]."
	var destination := Vector2i(int(step.to[0]), int(step.to[1]))
	if destination == unit.cell:
		return ""
	context.group.sync_occupancy()
	var path: Array[Vector2i] = context.group.grid.find_path(unit.cell, destination, unit.template.movement_profile)
	if path.size() < 2:
		return "Story walk destination is blocked or unreachable."
	var view: Control = context.layer.get_view(unit.id)
	if view == null:
		return "Story character has no display."
	var seconds: float = clampf(float(step.get("seconds_per_tile", 0.22)), 0.05, 3.0)
	await context.walk.play(view, context.board, path, seconds)
	unit.cell = destination
	context.group.sync_occupancy()
	context.layer.refresh()
	return ""
