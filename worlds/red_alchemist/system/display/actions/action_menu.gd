extends PanelContainer

signal chosen(action: StringName)
var buttons: Dictionary = {}
var title: Label

func _ready() -> void:
	custom_minimum_size = Vector2(280, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for action in [&"attack", &"items", &"wait", &"cancel"]:
		var button := Button.new()
		button.text = "Inventory" if action == &"items" else String(action).capitalize()
		button.custom_minimum_size.y = 44
		button.pressed.connect(func(): chosen.emit(action))
		button.mouse_entered.connect(button.grab_focus)
		column.add_child(button)
		buttons[action] = button
	hide()

func open(unit: RefCounted, turns: RefCounted, armed: bool) -> void:
	title.text = "%s\nMoves %d × %d · Actions %d" % [unit.template.display_name, ceili(float(turns.movement.remaining.get(unit.id, 0)) / maxi(1, unit.get_movement())), unit.get_movement(), turns.actions.remaining.get(unit.id, 0)]
	buttons[&"items"].disabled = not turns.can_act(unit)
	buttons[&"attack"].disabled = not turns.can_act(unit) or not armed
	show()
	reset_size()
	position = (get_viewport_rect().size - size) / 2
	for key in [&"attack", &"items", &"wait", &"cancel"]:
		if not buttons[key].disabled:
			buttons[key].grab_focus()
			break



