extends Control

signal advance_requested
var portrait: TextureRect
var placeholder: Label
var speaker_name: Label
var message: RichTextLabel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -240
	panel.offset_bottom = -24
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 18)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	var portrait_area := Control.new()
	portrait_area.custom_minimum_size = Vector2(144, 160)
	row.add_child(portrait_area)
	portrait = TextureRect.new()
	portrait_area.add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	placeholder = Label.new()
	portrait_area.add_child(placeholder)
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	speaker_name = Label.new()
	speaker_name.add_theme_font_size_override("font_size", 24)
	column.add_child(speaker_name)
	message = RichTextLabel.new()
	message.bbcode_enabled = false
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message.add_theme_font_size_override("normal_font_size", 21)
	column.add_child(message)
	var hint := Label.new()
	hint.text = "Click / Enter"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(hint)
	_ignore_mouse(self)
	hide()

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

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
