extends Node2D

signal save_and_return_requested
const MapGrid = preload("res://worlds/red_alchemist/system/map/map_grid.gd")
const NpcGroup = preload("res://worlds/red_alchemist/system/npc/npc_group.gd")
const Session = preload("res://worlds/red_alchemist/system/gameplay/battle/battle_session.gd")
const ActionMenu = preload("res://worlds/red_alchemist/system/display/actions/action_menu.gd")
const MovementDisplay = preload("res://worlds/red_alchemist/system/display/movement/movement_display.gd")
const ForecastPanel = preload("res://worlds/red_alchemist/system/display/battle_preview/forecast_panel.gd")
const Animations = preload("res://worlds/red_alchemist/system/animation/animation_manager.gd")
const ChapterData = preload("res://worlds/red_alchemist/system/chapter/chapter_data.gd")
@export_file("*.json") var chapter_source: String
var chapter_info: Dictionary = {}
var chapter_spawns: Dictionary = {}
const Events = preload("res://worlds/red_alchemist/system/story/events/event_manager.gd")
var events := Events.new()
var definition: Resource
var npc_spawns: Array[Resource] = []
@export var attribute_rules: Resource
var win_rules: Resource
var defeat_rules: Resource
var escape_cells: Array[Vector2i] = []
var npc_group: RefCounted
var grid: RefCounted
var session := Session.new()
var movement_display := MovementDisplay.new()
var animations := Animations.new()
var action_menu := ActionMenu.new()
var forecast_panel := ForecastPanel.new()
var overlay: Control
var end_turn_button: Button
var message: Label
const ItemMenu = preload("res://worlds/red_alchemist/system/display/inventory/item_menu.tscn")
const ItemUse = preload("res://worlds/red_alchemist/system/gameplay/inventory/item_use.gd")
var item_menu := ItemMenu.instantiate()
var item_use := ItemUse.new()
var actor: RefCounted
var target_cell: Vector2i
const MapSelection = preload("res://worlds/red_alchemist/system/display/map/selection/map_selection.gd")
var selection := MapSelection.new()
var mode: StringName = &"select"
var busy: bool = false
const CampaignState = preload("res://worlds/red_alchemist/system/save/campaign_state.gd")
var state_codec := CampaignState.new()
var saved_campaign: Dictionary = {}
var chapter_start: Dictionary = {}
var story: Dictionary = {"chapter": "chapter1", "node": "battle", "completed_chapters": [], "flags": {}}
var load_error: String = ""
var result_dialog: ConfirmationDialog
const DialogueManager = preload("res://worlds/red_alchemist/system/dialogue/dialogue_manager.gd")
const DialoguePanel = preload("res://worlds/red_alchemist/system/display/dialogue/dialogue_panel.gd")
const SceneRunner = preload("res://worlds/red_alchemist/system/story/scene_runner.gd")
const WalkAnimation = preload("res://worlds/red_alchemist/system/animation/effects/movement.gd")
var opening_scene: String = ""
var scene_runner := SceneRunner.new()
var dialogue := DialogueManager.new()
var dialogue_panel := DialoguePanel.new()
@onready var board = $Interface/Margin/Column/Board
@onready var layer = $Interface/Margin/Column/Board/Npcs
@onready var tile_info: Label = $Interface/Margin/Column/Footer/TileInfo
@onready var save_button: Button = $Interface/Margin/Column/Footer/SaveAndReturn

func _ready() -> void:
	if not _load_chapter():
		return
	grid = MapGrid.new(definition)
	board.configure(grid)
	npc_group = NpcGroup.new(npc_spawns, attribute_rules, grid)
	layer.configure(npc_group, board)
	session.begin(npc_group, win_rules, defeat_rules)
	events.configure(chapter_info.events, session)
	item_use.item_used.connect(events.record_item_use)
	session.battle.xp.points_per_level = attribute_rules.points_per_level
	session.escape_cells = escape_cells.duplicate()
	board.escape_cells = escape_cells.duplicate()
	add_child(animations)
	_build_controls()
	board.cell_selected.connect(_show_tile)
	board.cell_hovered.connect(_show_character)
	board.cell_activated.connect(_activate)
	board.resized.connect(func(): $Interface/CompactCharacter.hide())
	save_button.pressed.connect(func():
		if not busy:
			save_and_return_requested.emit())
	save_button.mouse_entered.connect(save_button.grab_focus)
	_show_tile(Vector2i.ZERO)
	_update_phase()
	_restore_campaign()
	if load_error.is_empty() and session.outcome.is_empty():
		_start_opening.call_deferred()

func _load_chapter() -> bool:
	var source := ChapterData.new()
	chapter_info = source.read(chapter_source)
	if chapter_info.is_empty():
		load_error = source.last_error
		return false
	definition = source.map_definition(chapter_info.map)
	chapter_spawns = source.placements(chapter_info.placements)
	for entry: Dictionary in chapter_info.placements.units:
		if bool(entry.initial):
			npc_spawns.append(chapter_spawns[String(entry.id)])
	for position: Array in chapter_info.map.escape_cells:
		escape_cells.append(source.cell(position))
	win_rules = source.objectives(chapter_info.objectives.win, true)
	defeat_rules = source.objectives(chapter_info.objectives.defeat, false)
	opening_scene = String(chapter_info.events.get("opening", ""))
	return true

func _build_controls() -> void:
	$Interface.add_child(dialogue_panel)
	dialogue_panel.z_index = 20
	dialogue_panel.advance_requested.connect(dialogue.advance)
	dialogue.line_changed.connect(_dialogue_line)
	dialogue.finished.connect(_dialogue_finished)
	scene_runner.step_started.connect(func(index: int): story["scene"] = {"source": opening_scene, "index": index})
	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.custom_minimum_size = Vector2(130, 48)
	$Interface/Margin/Column/Footer.add_child(end_turn_button)
	end_turn_button.pressed.connect(_end_turn)
	end_turn_button.mouse_entered.connect(end_turn_button.grab_focus)
	message = Label.new()
	message.custom_minimum_size.y = 48
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Interface/Margin/Column.add_child(message)
	overlay = Control.new()
	$Interface.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(action_menu)
	overlay.add_child(forecast_panel)
	overlay.add_child(item_menu)
	item_menu.confirmed.connect(_use_item)
	item_menu.cancelled.connect(_cancel)
	overlay.hide()
	action_menu.chosen.connect(_choose_action)
	forecast_panel.confirmed.connect(_confirm_attack)
	forecast_panel.cancelled.connect(_cancel)
	result_dialog = ConfirmationDialog.new()
	result_dialog.ok_button_text = "Save and Return"
	result_dialog.cancel_button_text = "Retry"
	add_child(result_dialog)
	result_dialog.confirmed.connect(func(): save_and_return_requested.emit())
	result_dialog.canceled.connect(_retry)

func focus_default() -> void:
	board.call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not busy:
			_cancel()

func _show_tile(cell: Vector2i) -> void:
	var terrain: Resource = grid.terrain_at(cell)
	if terrain != null:
		tile_info.text = terrain.display_name
	_show_character(cell)

func _show_character(cell: Vector2i) -> void:
	if busy or overlay.visible:
		$Interface/CompactCharacter.hide()
		return
	var character: RefCounted = npc_group.at_cell(cell)
	if character == null:
		$Interface/CompactCharacter.hide()
		return
	var anchor: Rect2 = board.cell_rect(cell)
	anchor.position += board.global_position
	$Interface/CompactCharacter.show_character(character, attribute_rules, anchor)

func _activate(cell: Vector2i) -> void:
	await selection.activate(self, cell)

func _open_actions() -> void:
	if actor == null or actor.current_hp <= 0 or actor.escaped:
		_clear_selection()
		return
	mode = &"actions"
	_set_overlay(true)
	action_menu.open(actor, session.turns, session.battle.rules.weapon(actor) != null)

func _choose_action(action: StringName) -> void:
	if not session.permits(action):
		_remind(action)
		return
	_set_overlay(false)
	match action:
		&"items":
			mode = &"items"
			_set_overlay(true)
			item_menu.open(actor, session.turns)
			return
		&"attack":
			mode = &"target"
			movement_display.clear(board)
			board.attack_cells = session.attack_cells(actor)
		&"wait":
			session.turns.wait_unit(actor)
			_clear_selection()
		&"cancel":
			selection.resume(self)
	board.queue_redraw()
	board.grab_focus()

func _cancel() -> void:
	if not session.permits(&"cancel"):
		_remind(&"cancel")
		return
	if mode == &"items":
		_open_actions()
		return
	if mode in [&"forecast", &"target", &"actions"]:
		_set_overlay(false)
		selection.resume(self)
	else:
		_set_overlay(false)
		_clear_selection()
	board.grab_focus()
func _confirm_attack() -> void:
	if not session.permits(&"attack"):
		_remind(&"attack")
		return
	if busy:
		return
	busy = true
	_set_overlay(false)
	_lock_controls()
	await _attack_unit(actor, target_cell)
	busy = false
	_lock_controls()
	if not _show_result():
		_open_actions()

func _move_unit(unit: RefCounted, destination: Vector2i) -> void:
	var path: Array[Vector2i] = session.move(unit, destination)
	if not path.is_empty():
		await animations.move_unit(layer.get_view(unit.id), board, path)
		layer.refresh()
		board._select(unit.cell)

func _attack_unit(unit: RefCounted, center: Vector2i) -> void:
	var result: Dictionary = session.attack(unit, center)
	if not result.error.is_empty():
		message.text = result.error
		return
	await animations.play(result.events, layer, message)

func _end_turn() -> void:
	if not busy and not session.permits(&"end_turn"):
		_remind(&"end_turn")
		return
	if busy or overlay.visible:
		return
	busy = true
	_clear_selection()
	_lock_controls()
	session.turns.next_phase(npc_group.npcs)
	while session.turns.current_faction() != &"player":
		_update_phase()
		for unit in npc_group.npcs:
			if unit.template.faction != session.turns.current_faction() or unit.current_hp <= 0 or unit.escaped:
				continue
			var request: Dictionary = session.npc_request(unit)
			if request.type == &"move":
				await _move_unit(unit, request.destination)
				if not session.result().is_empty():
					break
				request = session.npc_request(unit)
			if request.type == &"attack" and session.turns.can_act(unit):
				var target: RefCounted = npc_group.get_npc(request.target_id)
				if target != null:
					await _attack_unit(unit, target.cell)
			session.turns.wait_unit(unit)
			if not session.result().is_empty():
				break
		if not session.result().is_empty():
			break
		session.turns.next_phase(npc_group.npcs)
	if session.outcome.is_empty():
		await _run_events("player_turn_started")
	busy = false
	_lock_controls()
	if not _show_result():
		_update_phase()
		board.grab_focus()

func _show_result() -> bool:
	var result: StringName = session.result()
	if result.is_empty():
		return false
	busy = true
	_set_overlay(false)
	_clear_selection()
	_lock_controls()
	result_dialog.title = String(result).capitalize()
	result_dialog.dialog_text = "Victory" if result == &"victory" else "Defeat"
	result_dialog.popup_centered(Vector2i(360, 150))
	return true

func _retry() -> void:
	if not state_codec.restore(session, chapter_start, attribute_rules):
		message.text = state_codec.last_error
		return
	story = chapter_start.story.duplicate(true)
	_clear_selection()
	layer.refresh()
	busy = false
	_lock_controls()
	_update_phase()
	board.grab_focus()

func _restore_campaign() -> void:
	if saved_campaign.get("story") is Dictionary:
		story.merge(saved_campaign.story.duplicate(true), true)
	if saved_campaign.has("state_version"):
		if not saved_campaign.get("chapter_start") is Dictionary:
			load_error = "The chapter-start snapshot is missing."
		elif not state_codec.restore(session, saved_campaign, attribute_rules):
			load_error = state_codec.last_error
		if not load_error.is_empty():
			busy = true
			_lock_controls()
			return
		chapter_start = saved_campaign.chapter_start.duplicate(true)
	else:
		chapter_start = state_codec.capture(session, story)
	layer.refresh()
	_update_phase()
	if not session.outcome.is_empty():
		_show_result.call_deferred()

func capture_save() -> Dictionary:
	var state: Dictionary
	if session.outcome == &"defeat":
		state = chapter_start.duplicate(true)
	else:
		state = state_codec.capture(session, story)
		if session.outcome == &"victory":
			state.story["node"] = "chapter1_complete"
			for placement in state.map_state.units.values():
				placement["battle_bonuses"] = {}
				placement["extra_actions"] = 0
				placement["extra_moves"] = 0
			if not state.story.completed_chapters.has("chapter1"):
				state.story.completed_chapters.append("chapter1")
			for unit_id in state.map_state.units:
				if int(state.map_state.units[unit_id].hp) > 0:
					state.map_state.units[unit_id].hp = int(state.characters[unit_id].attributes.get(&"max_hp", 1))
	var roster: Dictionary = saved_campaign.get("characters", {}).duplicate(true)
	roster.merge(state.characters, true)
	state.characters = roster
	state["chapter_start"] = chapter_start.duplicate(true)
	return state
func _set_overlay(value: bool) -> void:
	overlay.visible = value
	action_menu.hide()
	forecast_panel.hide()
	item_menu.hide()
	$Interface/CompactCharacter.hide()
	_lock_controls()

func _lock_controls() -> void:
	board.input_enabled = not busy and not overlay.visible
	end_turn_button.disabled = busy or overlay.visible
	save_button.disabled = busy or overlay.visible
	if busy:
		$Interface/CompactCharacter.hide()

func _clear_selection() -> void:
	actor = null
	mode = &"select"
	movement_display.clear(board)
	board.attack_cells = {}
	board.queue_redraw()

func _update_phase() -> void:
	message.text = "Turn %d · %s" % [session.turns.round_number, String(session.turns.current_faction()).capitalize()]
	var objectives: String = session.objective_text()
	if not objectives.is_empty():
		message.text += "\n" + objectives
func _start_opening() -> void:
	if opening_scene.is_empty() or story.flags.get(String(chapter_info.events.get("opening_completed_flag", "opening_seen")), false):
		return
	var before: Dictionary = state_codec.capture(session, story)
	var start_index: int = 0
	if story.get("scene") is Dictionary and story.scene.get("source") == opening_scene:
		start_index = int(story.scene.get("index", 0))
	busy = true
	_lock_controls()
	var context: Dictionary = _story_context()
	var error: String = await scene_runner.play(opening_scene, context, start_index)
	dialogue_panel.hide()
	if error.is_empty():
		story.erase("scene")
		story.erase("dialogue")
		story.flags[String(chapter_info.events.get("opening_completed_flag", "opening_seen"))] = true
		chapter_start = state_codec.capture(session, story)
	else:
		if state_codec.restore(session, before, attribute_rules):
			story = before.story.duplicate(true)
			layer.refresh()
	busy = false
	_lock_controls()
	_update_phase()
	if not error.is_empty():
		message.text = error
	board.grab_focus()

func _dialogue_line(line: Dictionary, index: int) -> void:
	story["dialogue"] = {"source": dialogue.source, "index": index}
	dialogue_panel.show_line(line)

func _dialogue_finished() -> void:
	dialogue_panel.hide()
	story.erase("dialogue")


func _use_item(instance_id: StringName) -> void:
	if actor == null or busy:
		return
	var item: Resource = actor.inventory.get_item(instance_id)
	if item == null:
		return
	if not session.permits(&"use_item", actor.id, item.id):
		_remind(&"use_item", actor.id, item.id)
		return
	if not item_use.use(actor, instance_id, session.turns):
		return
	_set_overlay(false)
	busy = true
	_lock_controls()
	await _run_events("item_used")
	busy = false
	_clear_selection()
	_lock_controls()
	_update_phase()
	board.grab_focus()

func _remind(action: StringName, unit_id: StringName = &"", item_id: StringName = &"") -> void:
	if busy or dialogue.active:
		return
	var source: String = events.reminder(action, unit_id, item_id)
	if source.is_empty():
		return
	_set_overlay(false)
	busy = true
	_lock_controls()
	if dialogue.start(source):
		await dialogue.finished
	busy = false
	_clear_selection()
	_lock_controls()
	board.grab_focus()

func _story_context() -> Dictionary:
	return {"tree": get_tree(), "group": npc_group, "board": board, "layer": layer,
		"dialogue": dialogue, "walk": WalkAnimation.new(), "animations": animations,
		"message": message, "turns": session.turns, "attribute_rules": attribute_rules,
		"spawns": chapter_spawns}

func _run_events(trigger: String) -> void:
	var error: String = await events.dispatch(trigger, _story_context())
	layer.refresh()
	if not error.is_empty():
		message.text = error