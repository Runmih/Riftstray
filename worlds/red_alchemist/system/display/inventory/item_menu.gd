extends PanelContainer

signal confirmed(instance_id: StringName)
signal cancelled
const ItemUse = preload("res://worlds/red_alchemist/system/gameplay/inventory/item_use.gd")
var use_rules := ItemUse.new()
var selected_item: StringName
var _unit: RefCounted
var _turns: RefCounted
var _ids: Array[StringName] = []
@onready var slots: VBoxContainer = $Margin/Column/Slots
@onready var item_name: Label = $Margin/Column/Details/ItemName
@onready var description: RichTextLabel = $Margin/Column/Details/Description
@onready var use_button: Button = $Margin/Column/Details/Buttons/Use
@onready var back_button: Button = $Margin/Column/Details/Buttons/Back

func _ready() -> void:
	back_button.pressed.connect(func(): cancelled.emit())
	use_button.pressed.connect(_use_selected)
	for index in range(slots.get_child_count()):
		var button: Button = slots.get_child(index)
		button.focus_entered.connect(_select.bind(index))
		button.mouse_entered.connect(button.grab_focus)
		button.pressed.connect(_activate_slot.bind(index))
	for button: Button in [use_button, back_button]:
		button.mouse_entered.connect(button.grab_focus)

func open(unit: RefCounted, turns: RefCounted) -> void:
	_unit = unit
	_turns = turns
	_ids.clear()
	selected_item = &""
	for instance_id in unit.inventory.items:
		if not unit.gear.is_equipped(instance_id):
			_ids.append(StringName(instance_id))
	for index in range(slots.get_child_count()):
		var button: Button = slots.get_child(index)
		button.set_pressed_no_signal(false)
		button.disabled = index >= _ids.size()
		button.text = "— Empty —" if button.disabled else unit.inventory.get_item(_ids[index]).display_name
	show()
	if _ids.is_empty():
		item_name.text = "Inventory is empty"
		description.text = ""
		use_button.disabled = true
		back_button.grab_focus()
	else:
		_select(0)
		slots.get_child(0).grab_focus()

func _select(index: int) -> void:
	if index >= _ids.size():
		return
	selected_item = _ids[index]
	for slot_index in range(slots.get_child_count()):
		slots.get_child(slot_index).set_pressed_no_signal(slot_index == index)
	var item: Resource = _unit.inventory.get_item(selected_item)
	item_name.text = item.display_name
	description.text = item.description
	if item.use_effect != null:
		description.text += "\n\n" + item.use_effect.description_for(_unit)
	use_button.disabled = not use_rules.usable(_unit, _turns).has(selected_item)
	description.scroll_to_line(0)
	_focus_routes()

func _activate_slot(index: int) -> void:
	_select(index)
	if not use_button.disabled:
		use_button.grab_focus()

func _use_selected() -> void:
	if use_rules.usable(_unit, _turns).has(selected_item):
		confirmed.emit(selected_item)

func _focus_routes() -> void:
	var route: Array[Button] = []
	for button: Button in slots.get_children():
		if not button.disabled:
			route.append(button)
	if not use_button.disabled:
		route.append(use_button)
	route.append(back_button)
	for index in range(route.size()):
		var button: Button = route[index]
		var previous: NodePath = button.get_path_to(route[(index - 1 + route.size()) % route.size()])
		var next: NodePath = button.get_path_to(route[(index + 1) % route.size()])
		button.focus_previous = previous
		button.focus_next = next
		button.focus_neighbor_top = previous
		button.focus_neighbor_bottom = next
