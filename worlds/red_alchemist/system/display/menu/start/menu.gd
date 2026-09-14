extends Control

signal return_requested
signal new_game_requested
signal new_game_configured(slot: int, difficulty: StringName, mode: StringName)
signal continue_requested
signal load_game_requested
signal load_slot_requested(slot: int)
signal delete_slot_requested(slot: int)

@onready var start_menu = $Margin/Screens/StartMenu
@onready var new_game_screen = $Margin/Screens/NewGame
@onready var load_game_screen = $Margin/Screens/LoadGame
@onready var quit_dialog = $QuitDialog

func _ready() -> void:
	start_menu.new_game_requested.connect(_show_new_game)
	start_menu.continue_requested.connect(func(): continue_requested.emit())
	start_menu.load_game_requested.connect(_show_load_game)
	start_menu.back_requested.connect(func(): return_requested.emit())
	start_menu.quit_requested.connect(_request_quit)
	new_game_screen.back_requested.connect(_show_start)
	new_game_screen.confirmed.connect(func(slot: int, difficulty: StringName, mode: StringName): new_game_configured.emit(slot, difficulty, mode))
	load_game_screen.back_requested.connect(_show_start)
	load_game_screen.slot_requested.connect(func(slot: int): load_slot_requested.emit(slot))
	load_game_screen.delete_requested.connect(func(slot: int): delete_slot_requested.emit(slot))
	quit_dialog.confirmed.connect(_quit)
	quit_dialog.canceled.connect(_restore_focus)
	_show_start()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if new_game_screen.visible or load_game_screen.visible:
			_show_start()
		else:
			return_requested.emit()

func _show_new_game() -> void:
	load_game_screen.hide()
	start_menu.hide()
	new_game_screen.show()
	new_game_screen.focus_default()
	new_game_requested.emit()

func _show_start() -> void:
	load_game_screen.hide()
	new_game_screen.hide()
	start_menu.show()
	start_menu.focus_default()

func _request_quit() -> void:
	quit_dialog.popup_centered(Vector2i(360, 160))

func _restore_focus() -> void:
	if load_game_screen.visible:
		load_game_screen.focus_default()
	elif new_game_screen.visible:
		new_game_screen.focus_default()
	else:
		start_menu.focus_default()

func _quit() -> void:
	get_tree().quit()

func set_slots(slots: Array[Dictionary]) -> void:
	new_game_screen.set_slots(slots)
	load_game_screen.set_slots(slots)

func show_start() -> void:
	show()
	_show_start()


func _show_load_game() -> void:
	start_menu.hide()
	new_game_screen.hide()
	load_game_screen.show()
	load_game_requested.emit()
	load_game_screen.focus_default()

