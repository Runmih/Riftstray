class_name CrossworldDataWriter
extends RefCounted

var _service: CrossworldDataService
var _world_id: StringName


func _init(service: CrossworldDataService, world_id: StringName) -> void:
	_service = service
	_world_id = world_id


func set_fact(key: StringName, value: Variant) -> bool:
	return _service.set_world_fact(_world_id, key, value)


func get_status_message() -> String:
	return _service.get_status_message()
