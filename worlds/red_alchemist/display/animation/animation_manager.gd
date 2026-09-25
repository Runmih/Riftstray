extends Node

const Shake = preload("res://worlds/red_alchemist/display/animation/effects/damage_shake.gd")
const Glow = preload("res://worlds/red_alchemist/display/animation/effects/damage_glow.gd")
const Evade = preload("res://worlds/red_alchemist/display/animation/effects/evade.gd")
const Block = preload("res://worlds/red_alchemist/display/animation/effects/block.gd")
const Overpower = preload("res://worlds/red_alchemist/display/animation/effects/overpower.gd")
const Strike = preload("res://worlds/red_alchemist/display/animation/effects/strike.gd")
const Movement = preload("res://worlds/red_alchemist/display/animation/effects/movement.gd")
@export_range(0.25, 3.0) var speed: float = 1.0

func move_unit(view: Control, board: Control, path: Array[Vector2i]) -> void:
	await Movement.new().play(view, board, path, 0.16 / speed)

func play(events: Array, layer: Control, message: Label) -> void:
	for event: Dictionary in events:
		var attacker: Control = layer.get_view(event.attacker)
		var defender: Control = layer.get_view(event.defender)
		if attacker == null or defender == null:
			continue
		var direction: Vector2 = (defender.position - attacker.position).normalized()
		attacker.face_direction(direction)
		defender.face_direction(-direction)
		var result_text: String = "%d damage" % event.damage
		if not event.hit:
			result_text = "Evaded"
		elif event.overpowered:
			result_text = "Blocked · Stunned"
		elif event.blocked:
			result_text = "Blocked"
		var attack_name: String = String(event.attack_type).capitalize()
		if event.kind == &"riposte":
			attack_name = "Riposte"
		elif event.kind == &"counter":
			attack_name = "Counter · " + attack_name
		elif event.kind == &"follow_up":
			attack_name = "Follow-up · " + attack_name
		message.text = "%s → %s\n%s · %s" % [attacker.unit.template.display_name, defender.unit.template.display_name, attack_name, result_text]
		await Strike.new().play(attacker, 0.2 / speed, direction)
		if not event.hit:
			await Evade.new().play(defender, 0.4 / speed, direction)
		elif event.blocked:
			await Block.new().play(defender, 0.25 / speed, direction)
			if event.overpowered:
				await Overpower.new().play(defender, 0.4 / speed, direction)
		else:
			await Shake.new().play(defender, 0.2 / speed, direction)
			await Glow.new().play(defender, 0.2 / speed, direction)
		defender.set_hp(event.hp_after)
		await get_tree().create_timer(0.25 / speed).timeout
		if event.hp_after <= 0:
			defender.hide()
		if event.has("xp"):
			var progress: Dictionary = event["xp"]
			message.text = "%s · +%d XP\nLevel %d · %s" % [attacker.unit.template.display_name, progress.amount, progress.level, "MAX" if progress.at_cap else "%d / 100 XP" % progress.percent]
			if progress.levels_gained > 0:
				message.text += " · Level up!"
			await get_tree().create_timer(0.8 / speed).timeout
	layer.refresh()

