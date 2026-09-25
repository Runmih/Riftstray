extends RefCounted

func choose(cell: Vector2i, session: RefCounted, actor: RefCounted, targeting: bool) -> Dictionary:
	if session.turns.current_faction() != &"player":
		return {}
	var clicked: RefCounted = session.group.at_cell(cell)
	if clicked != null and clicked.template.faction == &"player":
		return {"type": &"actions"} if actor == clicked else {"type": &"select", "unit": clicked}
	if actor == null:
		return {"type": &"context"} if clicked == null else {}
	var hostile: bool = clicked != null and session.hostiles(actor).has(clicked.template.faction)
	if hostile or targeting:
		var rows: Array[Dictionary] = session.forecast(actor, cell)
		return {"type": &"forecast", "rows": rows} if not rows.is_empty() else {}
	if clicked != null:
		return {}
	if session.turns.can_move(actor) and session.turns.movement.reachable(actor, session.group).has(cell):
		if not session.permits(&"move", actor.id):
			return {"type": &"restricted", "action": &"move"}
		return {"type": &"move"}
	return {"type": &"context"}