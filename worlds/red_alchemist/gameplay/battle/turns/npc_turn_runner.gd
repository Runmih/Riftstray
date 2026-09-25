extends RefCounted

var active: bool = false

func run(session: RefCounted, present_move: Callable, present_attack: Callable, phase_changed: Callable, player_turn_started: Callable) -> void:
	if active or not session.permits(&"end_turn") or not session.result().is_empty():
		return
	active = true
	var turns: RefCounted = session.turns
	var group: RefCounted = session.group
	turns.next_phase(group.npcs)
	for phase in range(turns.phase_order.size()):
		if turns.current_faction() == &"player":
			break
		phase_changed.call()
		for unit in group.npcs:
			if unit.template.faction != turns.current_faction() or unit.current_hp <= 0 or unit.escaped:
				continue
			var request: Dictionary = session.npc_request(unit)
			if request.type == &"move":
				var path: Array[Vector2i] = session.move(unit, request.destination)
				if not path.is_empty():
					await present_move.call(unit, path)
				if not session.result().is_empty():
					break
				request = session.npc_request(unit)
			if request.type == &"attack" and turns.can_act(unit):
				var target: RefCounted = group.get_npc(request.target_id)
				if target != null:
					var exchange: Dictionary = session.attack(unit, target.cell)
					await present_attack.call(exchange)
			turns.wait_unit(unit)
			if not session.result().is_empty():
				break
		if not session.result().is_empty() or not turns.permits(&"end_turn"):
			break
		turns.next_phase(group.npcs)
	if session.result().is_empty() and turns.current_faction() == &"player":
		await player_turn_started.call()
		session.result()
	active = false