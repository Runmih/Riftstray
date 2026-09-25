extends RefCounted

const CAPACITY: int = 6
var last_error: String = ""
var _gear: WeakRef
var items: Dictionary = {}
var _owner: StringName
var _next_id := 1

func _init(owner_id: StringName) -> void:
	_owner = owner_id

func add_item(definition: Resource) -> StringName:
	last_error = ""
	if not has_space():
		last_error = "Inventory is full."
		return &""
	if definition == null:
		return &""
	var id := StringName("%s.item_%03d" % [_owner, _next_id])
	_next_id += 1
	items[id] = definition
	return id

func get_item(instance_id: StringName) -> Resource:
	return items.get(instance_id)

func next_item_id() -> int:
	return _next_id

func restore_items(restored: Dictionary, next_id: int) -> void:
	items = restored.duplicate()
	_next_id = maxi(1, next_id)
	for instance_id in items:
		_next_id = maxi(_next_id, String(instance_id).get_slice(".item_", 1).to_int() + 1)
func attach_gear(gear: RefCounted) -> void:
	_gear = weakref(gear)

func carried_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var gear: RefCounted = _gear.get_ref() if _gear != null else null
	for instance_id in items:
		if gear == null or not gear.is_equipped(StringName(instance_id)):
			result.append(StringName(instance_id))
	return result

func has_space() -> bool:
	return carried_ids().size() < CAPACITY