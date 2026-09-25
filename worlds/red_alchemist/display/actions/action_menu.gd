extends PanelContainer

signal chosen(action: StringName)
var buttons: Dictionary = {}
@onready var title: Label = $Column/Title

func _ready() -> void:
	buttons = {&"move": $Column/Move, &"attack": $Column/Attack, &"items": $Column/Inventory, &"wait": $Column/Wait, &"save": $Column/Save, &"end_turn": $Column/EndTurn, &"cancel": $Column/Cancel}
	for action in buttons:
		var button: Button = buttons[action]
		button.pressed.connect(func(): chosen.emit(action))
		button.mouse_entered.connect(button.grab_focus)

func open(unit: RefCounted, turns: RefCounted, armed: bool, anchor: Rect2 = Rect2()) -> void:
	var movable: bool = unit != null and turns.can_move(unit)
	var actionable: bool = unit != null and turns.can_act(unit)
	var active: bool = movable or actionable
	title.text = unit.template.display_name if unit != null else "Map"
	for key in [&"move", &"attack", &"items", &"wait"]:
		buttons[key].visible = active
	buttons[&"move"].disabled = not movable
	buttons[&"attack"].disabled = not actionable or not armed
	buttons[&"items"].disabled = not actionable
	buttons[&"wait"].disabled = not actionable
	show()
	reset_size()
	var viewport_size := get_viewport_rect().size
	var desired := anchor.end + Vector2(12, 0)
	if desired.x + size.x > viewport_size.x - 16:
		desired.x = anchor.position.x - size.x - 12
	position = Vector2(clampf(desired.x, 16, maxf(16, viewport_size.x - size.x - 16)), clampf(anchor.position.y, 16, maxf(16, viewport_size.y - size.y - 16)))
	for key in buttons:
		if buttons[key].visible and not buttons[key].disabled:
			buttons[key].grab_focus()
			break