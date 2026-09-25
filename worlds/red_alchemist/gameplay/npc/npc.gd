extends "res://worlds/red_alchemist/gameplay/character/character.gd"

func _init(spawn: Resource, rules: Resource) -> void:
	super(spawn, rules)
	allocations = rules.generate_npc_allocations(level, template.growth_priorities)
	var class_gains: Dictionary = template.character_class.gain_per_point if template.character_class != null else {}
	attributes = rules.calculate(template.base_attributes, allocations, class_gains)
	current_hp = int(attributes.get(&"max_hp", 1))
