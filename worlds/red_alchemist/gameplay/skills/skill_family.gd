extends Resource

@export var id: StringName
@export var display_name: String
@export var slots: Array[Resource] = []

func find_slot(slot_id: StringName) -> Resource:
	for slot: Resource in slots:
		if slot != null and slot.id == slot_id:
			return slot
	return null
