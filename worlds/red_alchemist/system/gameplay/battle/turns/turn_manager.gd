extends RefCounted

const Actions = preload("res://worlds/red_alchemist/system/gameplay/actions/action_manager.gd")
const Movement = preload("res://worlds/red_alchemist/system/gameplay/movement/movement_manager.gd")
var actions := Actions.new()
var movement := Movement.new()
var phase_order: Array[StringName] = [&"player", &"friendly", &"enemy"]
var round_number: int = 1
var phase_index: int = 0
var action_permission: Callable

func begin(units: Array) -> void:
	round_number = 1
	phase_index = 0
	_start_phase(units)

func current_faction() -> StringName:
	return phase_order[phase_index]

func can_act(unit: RefCounted) -> bool:
	return unit.template.faction == current_faction() and actions.available(unit)

func can_move(unit: RefCounted) -> bool:
	return unit.template.faction == current_faction() and movement.available(unit)

func spend_action(unit: RefCounted) -> bool:
	return actions.spend(unit) if can_act(unit) else false

func wait_unit(unit: RefCounted) -> void:
	if not permits(&"wait", unit.id):
		return
	actions.finish(unit.id)
	movement.finish(unit.id)

func next_phase(units: Array) -> void:
	if not permits(&"end_turn"):
		return
	for unit in units:
		if unit.template.faction == current_faction():
			unit.stunned = false
	phase_index = (phase_index + 1) % phase_order.size()
	if phase_index == 0:
		round_number += 1
	_start_phase(units)

func _start_phase(units: Array) -> void:
	actions.reset(units, current_faction())
	movement.reset(units, current_faction())


func permits(action: StringName, unit_id: StringName = &"", item_id: StringName = &"") -> bool:
	return not action_permission.is_valid() or bool(action_permission.call(action, unit_id, item_id))

func refresh_phase(units: Array) -> void:
	_start_phase(units)