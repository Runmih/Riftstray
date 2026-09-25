extends PanelContainer

@onready var column: VBoxContainer = $Margin/Column

func show_character(character: RefCounted, rules: Resource, anchor: Rect2) -> void:
	column.get_node("Name").text = character.template.display_name
	column.get_node("XP").visible = character.template.faction == &"player"
	column.get_node("XP").text = "XP: MAX" if character.level >= character.level_cap else "XP: %d / 100" % character.xp
	var class_title: String = character.template.character_class.display_name if character.template.character_class != null else ""
	column.get_node("Class").text = "%s · Level %d / %d · Move %d" % [class_title, character.level, character.level_cap, character.get_movement()]
	var maximum_hp: int = int(character.attributes.get(&"max_hp", 1))
	column.get_node("HP").text = "HP %d / %d" % [character.current_hp, maximum_hp]
	column.get_node("Bar").max_value = maximum_hp
	column.get_node("Bar").value = character.current_hp
	var attributes := PackedStringArray()
	for id in rules.labels:
		if StringName(id) != &"max_hp":
			attributes.append("%s %d" % [rules.labels[id], character.stat(StringName(id))])
	column.get_node("Attributes").text = "\n".join(attributes)
	var carried: Dictionary = {}
	for id in character.inventory.carried_ids():
		var item: Resource = character.inventory.get_item(id)
		carried[item.display_name] = int(carried.get(item.display_name, 0)) + 1
	var item_names := PackedStringArray()
	for name in carried:
		item_names.append("%s ×%d" % [name, carried[name]])
	column.get_node("Items").text = "Items: " + (", ".join(item_names) if not item_names.is_empty() else "None")
	var gear := PackedStringArray()
	for slot in character.gear.slot_names:
		var item: Resource = character.gear.item_in_slot(slot)
		gear.append("%s: %s" % [character.gear.slot_names[slot], item.display_name if item != null else "Empty"])
	column.get_node("Gear").text = "\n".join(gear)
	show()
	reset_size()
	_place_near.call_deferred(anchor)
func _place_near(anchor: Rect2) -> void:
	if not visible:
		return
	var bounds := get_viewport_rect().size
	var target := Vector2(anchor.end.x + 10, anchor.position.y)
	if target.x + size.x > bounds.x - 8:
		target.x = anchor.position.x - size.x - 10
	position = Vector2(clampf(target.x, 8, maxf(8, bounds.x - size.x - 8)), clampf(target.y, 8, maxf(8, bounds.y - size.y - 8)))

