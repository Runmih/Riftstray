extends PanelContainer

signal confirmed(instance_id: StringName)
signal cancelled
const ItemUse = preload("res://worlds/red_alchemist/gameplay/inventory/item_use.gd")
const InventoryRules = preload("res://worlds/red_alchemist/gameplay/inventory/inventory.gd")
var _page: int = 0
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

@onready var pages: HBoxContainer = $Margin/Column/Pages

func _ready() -> void:
	pages.get_node("Previous").pressed.connect(_change_page.bind(-1))
	pages.get_node("Next").pressed.connect(_change_page.bind(1))
	back_button.pressed.connect(func(): cancelled.emit())
	use_button.pressed.connect(_use_selected)
	for index in range(slots.get_child_count()):
		var button: Button = slots.get_child(index)
		button.focus_entered.connect(_select.bind(index))
		button.mouse_entered.connect(_preview_slot.bind(index))
		button.mouse_exited.connect(_restore_preview)
		button.gui_input.connect(_slot_input.bind(index))
		button.pressed.connect(_activate_slot.bind(index))
	for button: Button in [use_button, back_button]:
		button.mouse_entered.connect(button.grab_focus)

func open(unit: RefCounted, turns: RefCounted) -> void:
	_unit = unit
	_turns = turns
	_ids = unit.inventory.carried_ids()
	selected_item = &""
	_page = 0
	show()
	_refresh_slots()

func _refresh_slots() -> void:
	var offset: int = _page * InventoryRules.CAPACITY
	var count: int = maxi(1, ceili(float(_ids.size()) / InventoryRules.CAPACITY))
	pages.visible = count > 1
	pages.get_node("Previous").disabled = _page == 0
	pages.get_node("Next").disabled = _page >= count - 1
	pages.get_node("Number").text = "%d / %d" % [_page + 1, count]
	for index in range(slots.get_child_count()):
		var button: Button = slots.get_child(index)
		button.set_pressed_no_signal(false)
		button.disabled = index + offset >= _ids.size()
		button.text = "— Empty —" if button.disabled else _unit.inventory.get_item(_ids[index + offset]).display_name
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
	var absolute_index: int = index + _page * InventoryRules.CAPACITY
	if absolute_index >= _ids.size():
		return
	selected_item = _ids[absolute_index]
	for slot_index in range(slots.get_child_count()):
		slots.get_child(slot_index).set_pressed_no_signal(slot_index == index)
	_show_item(selected_item)
	use_button.disabled = not use_rules.usable(_unit, _turns).has(selected_item)
	_focus_routes()

func _activate_slot(index: int) -> void:
	_select(index)

func _use_selected() -> void:
	if use_rules.usable(_unit, _turns).has(selected_item):
		confirmed.emit(selected_item)

func _focus_routes() -> void:
	var route: Array[Button] = []
	for button: Button in slots.get_children():
		if not button.disabled:
			route.append(button)
	if pages.visible:
		for name: String in ["Previous", "Next"]:
			var page_button: Button = pages.get_node(name)
			if not page_button.disabled:
				route.append(page_button)
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

func _change_page(direction: int) -> void:
	var last: int = maxi(0, ceili(float(_ids.size()) / InventoryRules.CAPACITY) - 1)
	_page = clampi(_page + direction, 0, last)
	_refresh_slots()

func _show_item(instance_id: StringName) -> void:
	var item: Resource = _unit.inventory.get_item(instance_id)
	if item == null:
		return
	item_name.text = item.display_name
	var lines := PackedStringArray()
	if not item.description.is_empty():
		lines.append(item.description)
	for effect: Resource in item.use_effects:
		if effect != null:
			lines.append(effect.description_for(_unit))
	if not item.use_effects.is_empty():
		lines.append("Cost: 1 action · Consumed on use")
	description.text = "\n".join(lines)
	description.scroll_to_line(0)

func _preview_slot(index: int) -> void:
	var absolute_index: int = index + _page * InventoryRules.CAPACITY
	if absolute_index < _ids.size():
		_show_item(_ids[absolute_index])

func _restore_preview() -> void:
	_show_item(selected_item)

func _slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.double_click:
		_select(index)
		accept_event()
		_use_selected()