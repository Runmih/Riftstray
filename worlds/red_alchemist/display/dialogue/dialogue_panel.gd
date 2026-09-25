extends Control

signal advance_requested
@onready var portrait: TextureRect = $PortraitArea/Portrait
@onready var placeholder: Label = $PortraitArea/Placeholder
@onready var speaker_name: Label = $Panel/Margin/Row/Column/Speaker
@onready var message: RichTextLabel = $Panel/Margin/Row/Column/Message
func show_line(line: Dictionary) -> void:
	speaker_name.text = line.name
	message.text = line.text
	message.scroll_to_line(0)
	portrait.texture = null
	var path: String = line.portrait
	if not path.is_empty() and ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is Texture2D:
			portrait.texture = resource
	placeholder.text = line.name
	placeholder.visible = portrait.texture == null
	show()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		advance_requested.emit()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		advance_requested.emit()
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

