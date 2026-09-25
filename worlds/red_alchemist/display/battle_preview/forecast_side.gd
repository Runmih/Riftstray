extends VBoxContainer

func show_unit(unit: RefCounted, outgoing: Dictionary, incoming: Dictionary, count: int) -> void:
	$Name.text = unit.template.display_name
	$HP.text = "HP %d / %d" % [unit.current_hp, unit.attributes.get(&"max_hp", 1)]
	$Bar.current_hp = unit.current_hp
	$Bar.maximum_hp = int(unit.attributes.get(&"max_hp", 1))
	$Bar.loss = mini(unit.current_hp, int(incoming.get("damage", 0)))
	$Bar.color = unit.template.faction_color
	$Bar.queue_redraw()
	$Attack.text = "No counterattack" if outgoing.is_empty() else "Damage %d × %d\nHit %d%% · Crit %d%%" % [outgoing.damage, count, outgoing.hit, outgoing.critical]
	var details := PackedStringArray()
	for outcome: Dictionary in outgoing.get("outcomes", []):
		if outcome.id not in [&"normal", &"critical"] and outcome.probability > 0:
			details.append("%s %.1f%% · %d × %d damage" % [String(outcome.id).capitalize(), outcome.probability * 100, outcome.damage_per_hit, outcome.strikes])
	if not incoming.is_empty():
		if incoming.block_chance > 0:
			details.append("Block %d%% · 0 damage" % incoming.block_chance)
			for outcome: Dictionary in incoming.outcomes:
				if outcome.probability > 0 and outcome.block.overpowered:
					details.append("Overpowered block: stun")
					break
		if incoming.riposte_chance > 0:
			details.append("Riposte %d%% after dodge or full block\nRequires a weapon in range" % incoming.riposte_chance)
	$Details.text = "\n".join(details)
	$Details.visible = not details.is_empty()