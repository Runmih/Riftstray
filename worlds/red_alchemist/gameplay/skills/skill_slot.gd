extends Resource

@export var id: StringName
@export_range(1, 30) var unlock_level: int = 1
@export var choices: Array[Resource] = []

func find_skill(skill_id: StringName) -> Resource:
	if choices.size() != 2:
		return null
	for choice: Resource in choices:
		if choice != null and choice.id == skill_id:
			return choice
	return null
