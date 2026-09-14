class_name WorldContext
extends RefCounted

var world_id: StringName
var crossworld: CrossworldDataWriter

var _data_service: CrossworldDataService


func _init(id: StringName, data_service: CrossworldDataService) -> void:
	world_id = id
	_data_service = data_service
	crossworld = CrossworldDataWriter.new(data_service, id)


func get_fact(source_world_id: StringName, key: StringName, default_value: Variant = null) -> Variant:
	return _data_service.get_fact(source_world_id, key, default_value)


func set_fact(key: StringName, value: Variant) -> bool:
	return crossworld.set_fact(key, value)


func get_persistence_status() -> String:
	return _data_service.get_status_message()
