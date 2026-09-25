extends CenterContainer

signal new_game_requested
signal continue_requested
signal load_game_requested
signal quit_requested
signal back_requested

@onready var new_game_button: Button = $Column/NewGame

func _ready() -> void:
	new_game_button.pressed.connect(func(): new_game_requested.emit())
	$Column/Continue.pressed.connect(func(): continue_requested.emit())
	$Column/LoadGame.pressed.connect(func(): load_game_requested.emit())
	$Column/Quit.pressed.connect(func(): quit_requested.emit())
	$Column/Back.pressed.connect(func(): back_requested.emit())
	for child in $Column.get_children():
		if child is Button:
			child.mouse_entered.connect(_focus_hovered_button.bind(child))

func _focus_hovered_button(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()

func focus_default() -> void:
	new_game_button.call_deferred("grab_focus")
