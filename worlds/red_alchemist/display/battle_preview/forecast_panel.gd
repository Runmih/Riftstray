extends PanelContainer

signal confirmed
signal cancelled
const Pair = preload("res://worlds/red_alchemist/display/battle_preview/forecast_pair.tscn")
@onready var body: VBoxContainer = $Column/Scroll/Body
@onready var confirm_button: Button = $Column/Buttons/Attack
@onready var cancel_button: Button = $Column/Buttons/Cancel

func _ready() -> void:
	confirm_button.pressed.connect(func(): confirmed.emit())
	cancel_button.pressed.connect(func(): cancelled.emit())
	for button: Button in [confirm_button, cancel_button]:
		button.mouse_entered.connect(button.grab_focus)
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
		var sides = Pair.instantiate()
		body.add_child(sides)
		sides.get_node("Attacker").show_unit(attacker, row, counter, attacker_count)
		sides.get_node("Defender").show_unit(defender, counter, row, defender_count)
	show()
	reset_size()
	position = (get_viewport_rect().size - size) / 2
	confirm_button.grab_focus()

