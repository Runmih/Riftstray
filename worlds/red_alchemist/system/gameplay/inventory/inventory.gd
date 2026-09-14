extends RefCounted

var items: Dictionary = {}
var _owner: StringName
var _next_id := 1

func _init(owner_id: StringName) -> void:
	_owner = owner_id

func add_item(definition: Resource) -> StringName:
	if definition == null:
		return &""
	var id := StringName("%s.item_%03d" % [_owner, _next_id])
	_next_id += 1
	items[id] = definition
	return id

func get_item(instance_id: StringName) -> Resource:
	return items.get(instance_id)
