extends PanelContainer

@onready var column: VBoxContainer = $Margin/Column

func _ready() -> void:
	_ignore_mouse(self)

func show_character(character: RefCounted, rules: Resource, anchor: Rect2) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	_add_text(character.template.display_name, 21)
	if character.template.faction == &"player":
		_add_text("XP: MAX" if character.level >= character.level_cap else "XP: %d / 100" % character.xp)
	var class_title: String = character.template.character_class.display_name if character.template.character_class != null else ""
	_add_text("%s · Level %d / %d · Move %d" % [class_title, character.level, character.level_cap, character.get_movement()])
	var maximum_hp: int = int(character.attributes.get(&"max_hp", 1))
	_add_text("HP %d / %d" % [character.current_hp, maximum_hp])
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size.y = 12
	bar.show_percentage = false
	bar.max_value = maximum_hp
	bar.value = character.current_hp
	column.add_child(bar)
	var stats := GridContainer.new()
	stats.columns = 2
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_constant_override("h_separation", 16)
	column.add_child(stats)
	for attribute_id in rules.labels:
		if StringName(attribute_id) == &"max_hp":
			continue
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s %d" % [rules.labels[attribute_id], character.stat(StringName(attribute_id))]
		stats.add_child(label)
	var carried: Dictionary = {}
	for instance_id in character.inventory.items:
		if not character.gear.is_equipped(instance_id):
			var item: Resource = character.inventory.get_item(instance_id)
			carried[item.display_name] = int(carried.get(item.display_name, 0)) + 1
	var item_names := PackedStringArray()
	for item_name in carried:
		item_names.append("%s ×%d" % [item_name, carried[item_name]])
	_add_text("Items: " + (", ".join(item_names) if not item_names.is_empty() else "None"))
	for slot in character.gear.slot_names:
		var equipped_item: Resource = character.gear.item_in_slot(slot)
		_add_text("%s: %s" % [character.gear.slot_names[slot], equipped_item.display_name if equipped_item != null else "Empty"])
	show()
	reset_size()
	_place_near.call_deferred(anchor)

func _add_text(value: String, font_size: int = 16) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	column.add_child(label)

func _place_near(anchor: Rect2) -> void:
	if not visible:
		return
	var bounds := get_viewport_rect().size
	var target := Vector2(anchor.end.x + 10, anchor.position.y)
	if target.x + size.x > bounds.x - 8:
		target.x = anchor.position.x - size.x - 10
	position = Vector2(clampf(target.x, 8, maxf(8, bounds.x - size.x - 8)), clampf(target.y, 8, maxf(8, bounds.y - size.y - 8)))

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


