extends Resource

@export var checks: Array[Resource] = []
@export var require_all: bool = true

func evaluate(info: Dictionary) -> bool:
	if checks.is_empty():
		return false
	for check: Resource in checks:
		var passed: bool = check != null and check.matches(info)
		if require_all and not passed:
			return false
		if not require_all and passed:
			return true
	return require_all

func describe(info: Dictionary) -> String:
	var descriptions := PackedStringArray()
	for check: Resource in checks:
		if check != null:
			descriptions.append(check.describe(info))
	if descriptions.is_empty():
		return ""
	return ("All: " if require_all else "Any: ") + " · ".join(descriptions)
