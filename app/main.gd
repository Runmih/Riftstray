extends Control

const CATALOG_PATH := "res://content/world_catalog.tres"
const SCREEN_MAIN: StringName = &"main"
const SCREEN_WORLDS: StringName = &"worlds"
const SCREEN_OPTIONS: StringName = &"options"
const SCREEN_ACTIVE_WORLD: StringName = &"active_world"

var _catalog: WorldCatalog
var _crossworld_data: CrossworldDataService
var _settings: SettingsService
var _world_host: Control
var _menu_layer: Control
var _menu_root: Control
var _active_world: Node
var _active_context: WorldContext
var _current_screen: StringName = SCREEN_MAIN
var _crossworld_path_override := ""
var _settings_path_override := ""
var _options_status_label: Label


func configure_storage_paths_for_testing(crossworld_path: String, settings_path: String) -> void:
	_crossworld_path_override = crossworld_path
	_settings_path_override = settings_path


func _ready() -> void:
	set_process_unhandled_input(true)
	_build_shell()
	_load_catalog()
	var crossworld_path := CrossworldDataService.DEFAULT_PATH if _crossworld_path_override.is_empty() else _crossworld_path_override
	var settings_path := SettingsService.DEFAULT_PATH if _settings_path_override.is_empty() else _settings_path_override
	_crossworld_data = CrossworldDataService.new(crossworld_path)
	_settings = SettingsService.new(settings_path)
	_show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel") or _active_world != null:
		return
	match _current_screen:
		SCREEN_WORLDS, SCREEN_OPTIONS:
			get_viewport().set_input_as_handled()
			_show_main_menu()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("15191f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_world_host = Control.new()
	_world_host.name = "WorldHost"
	_world_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_world_host)

	_menu_layer = Control.new()
	_menu_layer.name = "MenuLayer"
	_menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_menu_layer)


func _load_catalog() -> void:
	var resource := load(CATALOG_PATH)
	if resource is WorldCatalog:
		_catalog = resource
	else:
		_catalog = WorldCatalog.new()


func _show_main_menu() -> void:
	_current_screen = SCREEN_MAIN
	var content := _create_menu_panel("Riftstray", "Choose where to go.")
	var select_world := _add_button(content, "Select World", Callable(self, "_show_world_selection"))
	_add_button(content, "Options", Callable(self, "_show_options"))
	_add_button(content, "Exit Game", Callable(self, "_exit_game"))
	var status := _crossworld_data.get_status_message()
	if not status.is_empty():
		_add_status(content, status, true)
	_focus(select_world)


func _show_world_selection() -> void:
	_current_screen = SCREEN_WORLDS
	var content := _create_menu_panel("Select World", "Available worlds are supplied by the world catalog.")
	var first_enabled: Button
	var problems: PackedStringArray = []
	var entries := _catalog.inspect_entries()
	if entries.is_empty():
		_add_status(content, "No worlds are registered.", true)
	for entry: Dictionary in entries:
		var definition: WorldDefinition = entry["definition"]
		var valid := bool(entry["is_valid"])
		var label := "Unavailable World"
		if definition != null and not definition.display_name.strip_edges().is_empty():
			label = definition.display_name
		if not valid:
			label += " (Unavailable)"
		var button := _add_button(content, label, Callable())
		button.disabled = not valid
		if valid:
			button.pressed.connect(Callable(self, "_launch_world").bind(definition))
			if first_enabled == null:
				first_enabled = button
		else:
			var problem := String(entry["error"])
			button.tooltip_text = problem
			problems.append(problem)
	if not problems.is_empty():
		_add_status(content, " ".join(problems), true)
	var back := _add_button(content, "Back", Callable(self, "_show_main_menu"))
	_add_hint(content, "Escape also returns to the main menu.")
	_focus(first_enabled if first_enabled != null else back)


func _show_options() -> void:
	_current_screen = SCREEN_OPTIONS
	var content := _create_menu_panel("Options", "Settings are stored separately from world data.")

	var volume_label := Label.new()
	volume_label.text = "Master Volume"
	volume_label.add_theme_font_size_override("font_size", 18)
	content.add_child(volume_label)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	content.add_child(volume_row)
	var slider := HSlider.new()
	slider.name = "MasterVolume"
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = _settings.master_volume * 100.0
	slider.custom_minimum_size = Vector2(280.0, 40.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(slider)
	var volume_value := Label.new()
	volume_value.custom_minimum_size.x = 52.0
	volume_value.text = "%d%%" % int(round(slider.value))
	volume_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_value)
	slider.value_changed.connect(Callable(self, "_on_volume_changed").bind(volume_value))

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.name = "Fullscreen"
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = _settings.fullscreen
	fullscreen_toggle.custom_minimum_size = Vector2(320.0, 44.0)
	fullscreen_toggle.toggled.connect(Callable(self, "_on_fullscreen_toggled"))
	content.add_child(fullscreen_toggle)

	_options_status_label = _add_status(content, "", true)
	_options_status_label.name = "OptionsStatus"
	_set_options_status(_settings.get_status_message())
	_add_button(content, "Back", Callable(self, "_show_main_menu"))
	_add_hint(content, "Escape also returns to the main menu.")
	_focus(slider)


func _on_volume_changed(value: float, value_label: Label) -> void:
	value_label.text = "%d%%" % int(round(value))
	_update_options_save_status(_settings.set_master_volume(value / 100.0))


func _on_fullscreen_toggled(enabled: bool) -> void:
	_update_options_save_status(_settings.set_fullscreen(enabled))


func _update_options_save_status(persisted: bool) -> void:
	if _options_status_label == null or not is_instance_valid(_options_status_label):
		return
	if persisted:
		_set_options_status("")
		return
	var message := "Changes apply only for the current session because settings could not be saved."
	var detail := _settings.get_status_message()
	if not detail.is_empty():
		message += " " + detail
	_set_options_status(message)


func _set_options_status(message: String) -> void:
	if _options_status_label == null or not is_instance_valid(_options_status_label):
		return
	_options_status_label.text = message
	_options_status_label.visible = not message.is_empty()


func _launch_world(definition: WorldDefinition) -> void:
	if definition == null:
		_show_launch_error("The selected world definition is missing.")
		return
	var validation_error := definition.validation_error()
	if not validation_error.is_empty():
		_show_launch_error(validation_error)
		return

	var candidate := definition.entry_scene.instantiate()
	if candidate == null:
		_show_launch_error("%s could not be instantiated." % definition.display_name)
		return
	if not candidate.has_method("start") or not candidate.has_signal("return_to_shell"):
		candidate.free()
		_show_launch_error("%s does not implement the world entry contract." % definition.display_name)
		return

	var return_callback := Callable(self, "_on_world_return_requested").bind(candidate)
	var connect_error := candidate.connect(&"return_to_shell", return_callback)
	if connect_error != OK:
		candidate.free()
		_show_launch_error("%s could not connect its return navigation." % definition.display_name)
		return

	_clear_menu()
	_set_shell_menu_active(false)
	_current_screen = SCREEN_ACTIVE_WORLD
	_active_world = candidate
	_active_context = WorldContext.new(definition.id, _crossworld_data)
	if not _crossworld_path_override.is_empty() and candidate.has_method("configure_profile_path_for_testing"):
		candidate.call("configure_profile_path_for_testing", _crossworld_path_override + ".%s_profile" % definition.id)
	_world_host.add_child(candidate)
	if candidate is Control:
		(candidate as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	candidate.call("start", _active_context)


func _on_world_return_requested(world: Node) -> void:
	if world != _active_world:
		return
	var return_callback := Callable(self, "_on_world_return_requested").bind(world)
	if world.is_connected(&"return_to_shell", return_callback):
		world.disconnect(&"return_to_shell", return_callback)
	if world.get_parent() == _world_host:
		_world_host.remove_child(world)
	world.queue_free()
	_active_world = null
	_active_context = null
	_show_world_selection()


func _show_launch_error(message: String) -> void:
	_show_world_selection()
	if _menu_root != null:
		var panel_content := _menu_root.get_node_or_null("Panel/Margin/Content")
		if panel_content is VBoxContainer:
			_add_status(panel_content, message, true)


func _exit_game() -> void:
	get_tree().quit()


func _create_menu_panel(title: String, subtitle: String) -> VBoxContainer:
	_clear_menu()
	_set_shell_menu_active(true)
	_options_status_label = null
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_layer.add_child(center)
	_menu_root = center

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(500.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("222832")
	panel_style.border_color = Color("495263")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	content.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_color_override("font_color", Color("b8c0cc"))
	content.add_child(subtitle_label)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8.0
	content.add_child(spacer)
	return content


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360.0, 46.0)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_status(parent: VBoxContainer, message: String, is_error: bool) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("ffb4a8") if is_error else Color("b8c0cc"))
	parent.add_child(label)
	return label


func _add_hint(parent: VBoxContainer, message: String) -> void:
	var label := _add_status(parent, message, false)
	label.add_theme_font_size_override("font_size", 13)


func _focus(control: Control) -> void:
	if control != null:
		control.call_deferred("grab_focus")


func _clear_menu() -> void:
	if _menu_root == null:
		return
	_menu_root.queue_free()
	_menu_root = null


func _set_shell_menu_active(active: bool) -> void:
	if _menu_layer == null:
		return
	_menu_layer.visible = active
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
