extends Resource

@export var id: StringName
@export var display_name: String
@export var nation: StringName
@export var faction: StringName = &"player"
@export var faction_color := Color("4c94db")
@export var sprite: Texture2D
@export var base_attributes: Dictionary = {}
@export var default_level: int = 1
@export var level_cap: int = 30
@export var movement_profile: StringName = &"ground"
@export var character_class: Resource
@export_range(0, 30) var classless_movement: int = 0
@export var starting_items: Array[Resource] = []
@export var starting_gear: Dictionary = {}
var is_named := true
@export var selected_skills: Dictionary = {}
@export var tags: Array[StringName] = []
