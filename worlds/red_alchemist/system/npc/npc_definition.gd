extends "res://worlds/red_alchemist/system/character/character_definition.gd"

@export var growth_priorities: Array[StringName] = []

func _init() -> void:
	is_named = false
	faction = &"enemy"
	faction_color = Color("c64b50")
