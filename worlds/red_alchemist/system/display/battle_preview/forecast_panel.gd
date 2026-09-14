extends PanelContainer

signal confirmed
signal cancelled
const HPForecast = preload("res://worlds/red_alchemist/system/display/battle_preview/hp_forecast.gd")
var body: VBoxContainer
var confirm_button: Button
var cancel_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2(620, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 290)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	confirm_button = Button.new()
	confirm_button.text = "Attack"
	confirm_button.custom_minimum_size = Vector2(180, 44)
	confirm_button.pressed.connect(func(): confirmed.emit())
	confirm_button.mouse_entered.connect(confirm_button.grab_focus)
	buttons.add_child(confirm_button)
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(180, 44)
	cancel_button.pressed.connect(func(): cancelled.emit())
	cancel_button.mouse_entered.connect(cancel_button.grab_focus)
	buttons.add_child(cancel_button)
	hide()

func open(rows: Array[Dictionary], group: RefCounted) -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var shown: Dictionary = {}
	for row: Dictionary in rows:
		if row.kind != &"initial" or shown.has(row.defender):
			continue
		shown[row.defender] = true
		var attacker: RefCounted = group.get_npc(row.attacker)
		var defender: RefCounted = group.get_npc(row.defender)
		var counter: Dictionary = {}
		var attacker_count: int = 0
		var defender_count: int = 0
		for step: Dictionary in rows:
			if step.attacker == attacker.id and step.defender == defender.id:
				attacker_count += 1
			elif step.attacker == defender.id and step.defender == attacker.id:
				defender_count += 1
				counter = step
		var sides := HBoxContainer.new()
		sides.add_theme_constant_override("separation", 24)
		body.add_child(sides)
		_side(sides, attacker, row, counter, attacker_count)
		_side(sides, defender, counter, row, defender_count)
	_text(body, "White HP: loss from one normal hit without a block. Later strikes require survival and no stun.")
	show()
	reset_size()
	position = (get_viewport_rect().size - size) / 2
	confirm_button.grab_focus()

func _side(parent: Control, unit: RefCounted, outgoing: Dictionary, incoming: Dictionary, count: int) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 270
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	_text(column, unit.template.display_name, 21)
	_text(column, "HP %d / %d" % [unit.current_hp, unit.attributes.get(&"max_hp", 1)])
	var bar := HPForecast.new()
	bar.current_hp = unit.current_hp
	bar.maximum_hp = int(unit.attributes.get(&"max_hp", 1))
	bar.loss = mini(unit.current_hp, int(incoming.get("damage", 0)))
	bar.color = unit.template.faction_color
	column.add_child(bar)
	if outgoing.is_empty():
		_text(column, "No counterattack")
	else:
		_text(column, "Damage %d × %d\nHit %d%% · Crit %d%%" % [outgoing.damage, count, outgoing.hit, outgoing.critical])
		for outcome: Dictionary in outgoing.outcomes:
			if outcome.id not in [&"normal", &"critical"] and outcome.probability > 0:
				_text(column, "%s %.1f%% · %d × %d damage" % [String(outcome.id).capitalize(), outcome.probability * 100, outcome.damage_per_hit, outcome.strikes])
	if not incoming.is_empty():
		if incoming.block_chance > 0:
			_text(column, "Block %d%% · 0 damage" % incoming.block_chance)
			for outcome: Dictionary in incoming.outcomes:
				if outcome.probability > 0 and outcome.block.overpowered:
					_text(column, "Overpowered block: stun")
					break
		if incoming.riposte_chance > 0:
			_text(column, "Riposte %d%% after dodge or full block\nRequires a weapon in range" % incoming.riposte_chance)

func _text(parent: Control, value: String, font_size: int = 17) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
