extends RefCounted

const Inventory = preload("res://worlds/red_alchemist/system/gameplay/inventory/inventory.gd")
const Gear = preload("res://worlds/red_alchemist/system/gameplay/gear/gear.gd")
var id: StringName
var template: Resource
var level: int
var level_cap: int
var cell: Vector2i
var allocations: Dictionary = {}
var attributes: Dictionary = {}
var current_hp: int
var behavior: Resource
var inventory: RefCounted
var gear: RefCounted
var skills: RefCounted
const Skills = preload("res://worlds/red_alchemist/system/gameplay/skills/skills.gd")

func _init(spawn: Resource, rules: Resource) -> void:
	id = spawn.id
	template = spawn.template
	level_cap = mini(template.level_cap, rules.maximum_level)
	level = clampi(spawn.level if spawn.level > 0 else template.default_level, 1, level_cap)
	cell = spawn.cell
	behavior = spawn.behavior.duplicate(true) if spawn.behavior != null else null
	attributes = template.base_attributes.duplicate(true)
	current_hp = int(attributes.get(&"max_hp", 1))
	inventory = Inventory.new(id)
	gear = Gear.new(inventory)
	skills = Skills.new(self, template.selected_skills)
	for item: Resource in template.starting_items:
		var instance_id: StringName = inventory.add_item(item)
		for slot in template.starting_gear:
			if item.id == StringName(template.starting_gear[slot]) and not gear.equipped.has(slot):
				gear.equip(instance_id, StringName(slot))

func get_movement() -> int:
	return template.character_class.movement if template.character_class != null else template.classless_movement


var stunned: bool = false
var escaped: bool = false
var xp: int = 0
var unspent_attribute_points: int = 0
var permanent_hp_loss: int = 0
var battle_bonuses: Dictionary = {}
var extra_actions: int = 0
var consumed_unique_items: Array[StringName] = []

func stat(attribute: StringName) -> int:
	return int(attributes.get(attribute, 0)) + int(battle_bonuses.get(attribute, 0))
var extra_moves: int = 0
