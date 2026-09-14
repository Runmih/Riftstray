extends CenterContainer

signal back_requested
signal confirmed(slot: int, difficulty: StringName, mode: StringName)

const DIFFICULTIES = [&"easy", &"normal", &"hard"]
const MODES = [&"casual", &"classic"]

@onready var difficulty: OptionButton = $Panel/Margin/Column/Difficulty
@onready var mode: OptionButton = $Panel/Margin/Column/Mode
@onready var slot_picker: OptionButton = $Panel/Margin/Column/Slot
@onready var description: Label = $Panel/Margin/Column/ModeDescription
@onready var confirm_button: Button = $Panel/Margin/Column/Actions/Confirm
@onready var back_button: Button = $Panel/Margin/Column/Actions/Back

func _ready() -> void:
	mode.item_selected.connect(_update_description)
	confirm_button.pressed.connect(_confirm)
	back_button.pressed.connect(func(): back_requested.emit())
	for button in [difficulty, mode, slot_picker, confirm_button, back_button]:
		button.mouse_entered.connect(_focus_hovered.bind(button))
	_update_description(mode.selected)

func set_slots(slots: Array[Dictionary]) -> void:
	slot_picker.clear()
	var first_empty := -1
	for slot in slots:
		var index := slot_picker.item_count
		slot_picker.add_item(slot["label"], slot["id"])
		slot_picker.set_item_disabled(index, slot["occupied"])
		if first_empty == -1 and not slot["occupied"]:
			first_empty = index
	slot_picker.select(first_empty)
	slot_picker.disabled = first_empty == -1
	confirm_button.disabled = first_empty == -1

func focus_default() -> void:
	difficulty.call_deferred("grab_focus")

func _confirm() -> void:
	if slot_picker.selected >= 0:
		confirmed.emit(slot_picker.get_selected_id(), DIFFICULTIES[difficulty.selected], MODES[mode.selected])

func _focus_hovered(button: BaseButton) -> void:
	if not button.disabled:
		button.grab_focus()

func _update_description(index: int) -> void:
	description.text = "Fallen allies return after the battle." if index == 0 else "Fallen allies are permanently lost."
