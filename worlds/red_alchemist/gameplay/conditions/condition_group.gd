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

func progress(info: Dictionary) -> Dictionary:
	var values: Array[Dictionary] = []
	for check: Resource in checks:
		if check != null:
			values.append(check.progress(info))
	return {"require_all": require_all, "checks": values}