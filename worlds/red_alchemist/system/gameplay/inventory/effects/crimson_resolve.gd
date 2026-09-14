extends Resource

@export var owner: StringName = &"mihata"
@export_range(0.01, 1.0) var remaining_hp_ratio: float = 0.75
@export var extra_actions: int = 1
@export var extra_moves: int = 1

func available(unit: RefCounted, item: Resource) -> bool:
	return unit.id == owner and not unit.consumed_unique_items.has(item.id)

func description_for(unit: RefCounted) -> String:
	var before: int = int(unit.attributes.get(&"max_hp", 1))
	var after: int = maxi(1, floori(before * remaining_hp_ratio))
	return "Maximum HP: %d → %d permanently.\n\nFor this battle: %d moves of up to %d tiles and %d actions per player turn.\n\nDrinking spends one action. In this opening tutorial, your first full turn begins immediately afterward. Retry restores the chapter-start potion and HP." % [before, after, 1 + extra_moves, unit.get_movement(), 1 + extra_actions]

func apply(unit: RefCounted, item: Resource) -> void:
	var before: int = int(unit.attributes.get(&"max_hp", 1))
	var after: int = maxi(1, floori(before * remaining_hp_ratio))
	unit.permanent_hp_loss += before - after
	unit.attributes[&"max_hp"] = after
	unit.current_hp = mini(unit.current_hp, after)
	unit.extra_actions += extra_actions
	unit.extra_moves += extra_moves
	unit.consumed_unique_items.append(item.id)
