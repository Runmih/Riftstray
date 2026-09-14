class_name TacticalOwnedItemInstance
extends RefCounted

var id: StringName
var definition_id: StringName


func duplicate_instance() -> TacticalOwnedItemInstance:
	var copy := TacticalOwnedItemInstance.new()
	copy.id = id
	copy.definition_id = definition_id
	return copy
