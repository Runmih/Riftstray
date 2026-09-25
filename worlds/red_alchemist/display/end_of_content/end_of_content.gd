extends Control

signal return_requested

func _ready() -> void:
	$Center/Column/Return.pressed.connect(func(): return_requested.emit())
	$Center/Column/Return.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return_requested.emit()