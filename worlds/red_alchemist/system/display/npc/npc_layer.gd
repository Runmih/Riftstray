extends Control

const UnitView = preload("res://worlds/red_alchemist/system/display/npc/unit_view.gd")
var group: RefCounted
var board: Control
var views: Dictionary = {}

func configure(npc_group: RefCounted, map_board: Control) -> void:
	group = npc_group
	board = map_board
	board.resized.connect(refresh)
	refresh()

func refresh() -> void:
	for unit_id in views.keys():
		if group.get_npc(unit_id) == null:
			views[unit_id].queue_free()
			views.erase(unit_id)
	for unit in group.npcs:
		if not views.has(unit.id):
			var view := UnitView.new()
			add_child(view)
			view.configure(unit)
			views[unit.id] = view
		var view: Control = views[unit.id]
		if view.unit != unit:
			view.configure(unit)
		var rect: Rect2 = board.cell_rect(unit.cell)
		view.position = rect.position
		view.size = rect.size
		view.visible = unit.current_hp > 0 and not unit.escaped
		view.set_hp(unit.current_hp)
		view.queue_redraw()

func get_view(unit_id: StringName) -> Control:
	return views.get(unit_id)

