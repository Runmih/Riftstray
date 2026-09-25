extends RefCounted

const SOURCE = "res://worlds/red_alchemist/content/campaign.json"

static func catalog() -> Dictionary:
	var file := FileAccess.open(SOURCE, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func initial() -> String:
	return String(catalog().get("start", ""))

static func find(location: String) -> Dictionary:
	return catalog().get("locations", {}).get(location, {})