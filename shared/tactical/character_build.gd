class_name TacticalCharacterBuild
extends RefCounted

var character_id: StringName
var level := 1
var attribute_allocations: Dictionary = {}
var purchased_skill_ids: Array[StringName] = []


func duplicate_build() -> TacticalCharacterBuild:
	var copy := TacticalCharacterBuild.new()
	copy.character_id = character_id
	copy.level = level
	copy.attribute_allocations = attribute_allocations.duplicate(true)
	copy.purchased_skill_ids = purchased_skill_ids.duplicate()
	return copy
