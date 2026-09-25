extends RefCounted

var selected: Dictionary = {}
var last_error: String = ""
var _character: WeakRef

func _init(character: RefCounted, starting_selection: Dictionary) -> void:
	_character = weakref(character)
	for slot_id in starting_selection:
		var skill_id := StringName(starting_selection[slot_id])
		if _available(StringName(slot_id), skill_id):
			selected[StringName(slot_id)] = skill_id

func get_family() -> Resource:
	var character_class: Resource = _character.get_ref().template.character_class
	return character_class.skill_family if character_class != null else null

func select_skill(slot_id: StringName, skill_id: StringName, in_preparation: bool = false) -> bool:
	last_error = ""
	if not in_preparation:
		last_error = "Skills can only be changed during preparation."
		return false
	if not _available(slot_id, skill_id):
		last_error = "This skill is not an unlocked choice for this slot."
		return false
	selected[slot_id] = skill_id
	return true

func active_skills() -> Array[Resource]:
	var result: Array[Resource] = []
	var family: Resource = get_family()
	if family == null:
		return result
	for slot: Resource in family.slots:
		if slot == null or not selected.has(slot.id):
			continue
		var skill_id := StringName(selected[slot.id])
		if _available(slot.id, skill_id):
			result.append(slot.find_skill(skill_id))
	return result

func _available(slot_id: StringName, skill_id: StringName) -> bool:
	var family: Resource = get_family()
	if family == null or family.slots.size() > 6:
		return false
	var slot: Resource = family.find_slot(slot_id)
	return slot != null and _character.get_ref().level >= slot.unlock_level and slot.find_skill(skill_id) != null

