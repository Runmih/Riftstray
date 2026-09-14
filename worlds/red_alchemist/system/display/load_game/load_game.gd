extends CenterContainer

signal back_requested
signal slot_requested(slot: int)
signal delete_requested(slot: int)

var _load_buttons: Array[Button] = []
var _delete_buttons: Array[Button] = []
var _pending_delete := 0
var _last_slot := 1
@onready var rows: VBoxContainer = $Panel/Margin/Column/Slots
@onready var back_button: Button = $Panel/Margin/Column/Back
@onready var delete_dialog: ConfirmationDialog = $ConfirmDelete

func _ready() -> void:
	for slot in range(1, 7):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		rows.add_child(row)
		var load_button := Button.new()
		load_button.custom_minimum_size = Vector2(0, 44)
		load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		load_button.text = "Slot %d — Empty" % slot
		load_button.disabled = true
		row.add_child(load_button)
		load_button.pressed.connect(_select_slot.bind(slot))
		load_button.mouse_entered.connect(_hover.bind(load_button))
		_load_buttons.append(load_button)
		var delete_button := Button.new()
		delete_button.text = "Delete"
		delete_button.custom_minimum_size = Vector2(72, 44)
		delete_button.add_theme_font_size_override("font_size", 18)
		delete_button.disabled = true
		row.add_child(delete_button)
		delete_button.pressed.connect(_ask_delete.bind(slot))
		delete_button.mouse_entered.connect(_hover.bind(delete_button))
		_delete_buttons.append(delete_button)
	back_button.pressed.connect(func(): back_requested.emit())
	back_button.mouse_entered.connect(back_button.grab_focus)
	delete_dialog.confirmed.connect(_confirm_delete)
	delete_dialog.canceled.connect(focus_default)

func set_slots(slots: Array[Dictionary]) -> void:
	for slot in slots:
		var index: int = int(slot["id"]) - 1
		if index < 0 or index >= _load_buttons.size():
			continue
		_load_buttons[index].text = slot["label"]
		_load_buttons[index].disabled = not slot["loadable"]
		_delete_buttons[index].disabled = not slot["occupied"]

func focus_default() -> void:
	var index := _last_slot - 1
	if index >= 0 and index < _load_buttons.size() and not _load_buttons[index].disabled:
		_load_buttons[index].call_deferred("grab_focus")
		return
	for button in _load_buttons:
		if not button.disabled:
			button.call_deferred("grab_focus")
			return
	for button in _delete_buttons:
		if not button.disabled:
			button.call_deferred("grab_focus")
			return
	back_button.call_deferred("grab_focus")

func _select_slot(slot: int) -> void:
	_last_slot = slot
	slot_requested.emit(slot)

func _ask_delete(slot: int) -> void:
	_pending_delete = slot
	_last_slot = slot
	delete_dialog.dialog_text = "Delete Slot %d? This cannot be undone." % slot
	delete_dialog.popup_centered(Vector2i(380, 160))
	delete_dialog.get_cancel_button().call_deferred("grab_focus")

func _confirm_delete() -> void:
	var slot := _pending_delete
	_pending_delete = 0
	if slot > 0:
		delete_requested.emit(slot)

func _hover(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()
