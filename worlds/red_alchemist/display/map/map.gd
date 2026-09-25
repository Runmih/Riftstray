extends Node2D

signal save_and_return_requested
const MapGrid = preload("res://worlds/red_alchemist/gameplay/map/map_grid.gd")
const NpcGroup = preload("res://worlds/red_alchemist/gameplay/npc/npc_group.gd")
const Session = preload("res://worlds/red_alchemist/gameplay/battle/battle_session.gd")
const MovementDisplay = preload("res://worlds/red_alchemist/display/movement/movement_display.gd")
const Animations = preload("res://worlds/red_alchemist/display/animation/animation_manager.gd")
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
const EscapeHandler = preload("res://worlds/red_alchemist/gameplay/movement/destinations/escape_handler.gd")
const NpcTurns = preload("res://worlds/red_alchemist/gameplay/battle/turns/npc_turn_runner.gd")
var escape_handler := EscapeHandler.new()
var npc_turns := NpcTurns.new()
var npc_group: RefCounted
var grid: RefCounted
var session := Session.new()
const ObjectiveText = preload("res://worlds/red_alchemist/display/objectives/objective_text.gd")
var objective_text := ObjectiveText.new()
var movement_display := MovementDisplay.new()
var animations := Animations.new()
@onready var action_menu = $Interface/Overlay/ActionMenu
@onready var forecast_panel = $Interface/Overlay/Forecast
@onready var overlay: Control = $Interface/Overlay
@onready var message: Label = $Interface/Margin/Column/Message
const ItemUse = preload("res://worlds/red_alchemist/gameplay/inventory/item_use.gd")
@onready var item_menu = $Interface/Overlay/Inventory
var item_use := ItemUse.new()
var actor: RefCounted
var target_cell: Vector2i
const MapSelection = preload("res://worlds/red_alchemist/display/map/selection/map_selection.gd")
var selection := MapSelection.new()
var mode: StringName = &"select"
var busy: bool = false
const CampaignState = preload("res://worlds/red_alchemist/system/save/campaign_state.gd")
var state_codec := CampaignState.new()
var saved_campaign: Dictionary = {}
var chapter_start: Dictionary = {}
var story: Dictionary = {"flags": {}}
var load_error: String = ""
@onready var result_dialog: ConfirmationDialog = $Result
const DialogueManager = preload("res://worlds/red_alchemist/system/dialogue/dialogue_manager.gd")
const SceneRunner = preload("res://worlds/red_alchemist/system/story/scene_runner.gd")
const WalkAnimation = preload("res://worlds/red_alchemist/display/animation/effects/movement.gd")
var opening_scene: String = ""
var scene_runner := SceneRunner.new()
var dialogue := DialogueManager.new()
@onready var dialogue_panel = $Interface/Dialogue
@onready var board = $Interface/Board
@onready var layer = $Interface/Board/Npcs
@onready var tile_info: Label = $Interface/Margin/Column/Footer/TileInfo

func _ready() -> void:
	if not _load_chapter():
		return
	grid = MapGrid.new(definition)
	board.configure(grid, chapter_source.get_base_dir())
	board.resized.connect(_layout_weather)
	_layout_weather.call_deferred()
	npc_group = NpcGroup.new(npc_spawns, attribute_rules, grid)
	layer.configure(npc_group, board)
	session.begin(npc_group, win_rules, defeat_rules)
	events.configure(chapter_info.events, session)
	item_use.item_used.connect(events.record_item_use)
	session.battle.xp.points_per_level = attribute_rules.points_per_level
	escape_handler.configure(chapter_info.map.get("escape_rules", []), npc_group, session.turns)
	session.unit_moved.connect(escape_handler.on_unit_moved)
	board.escape_cells = escape_handler.marker_cells()
	add_child(animations)
	_build_controls()
	board.cell_selected.connect(_show_tile)
	board.cell_hovered.connect(_show_character)
	board.cell_activated.connect(_activate)
	board.resized.connect(func(): $Interface/CompactCharacter.hide())
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
	story["location"] = String(chapter_info.id)
	state_codec.map_id = String(chapter_info.id)
	state_codec.map_revision = int(chapter_info.get("map_revision", 1))
	definition = source.map_definition(chapter_info.map)
	chapter_spawns = source.placements(chapter_info.placements)
	for entry: Dictionary in chapter_info.placements.units:
		if bool(entry.initial):
			npc_spawns.append(chapter_spawns[String(entry.id)])
	win_rules = source.objectives(chapter_info.objectives.win, true)
	defeat_rules = source.objectives(chapter_info.objectives.defeat, false)
	opening_scene = String(chapter_info.events.get("opening", ""))
	return true

func _build_controls() -> void:
	dialogue_panel.advance_requested.connect(dialogue.advance)
	dialogue.line_changed.connect(_dialogue_line)
	dialogue.finished.connect(_dialogue_finished)
	scene_runner.step_started.connect(func(index: int): story["scene"] = {"source": opening_scene, "index": index})
	item_menu.confirmed.connect(_use_item)
	item_menu.cancelled.connect(_cancel)
	overlay.hide()
	action_menu.chosen.connect(_choose_action)
	forecast_panel.confirmed.connect(_confirm_attack)
	forecast_panel.cancelled.connect(_cancel)
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
	if actor == null:
		if character != null and character.template.faction == &"player":
			movement_display.show_range(board, character, session)
		else:
			movement_display.clear(board)
	if character == null:
		$Interface/CompactCharacter.hide()
		return
	var anchor: Rect2 = board.cell_rect(cell)
	anchor.position += board.global_position
	$Interface/CompactCharacter.show_character(character, attribute_rules, anchor)

func _activate(cell: Vector2i) -> void:
	if busy or overlay.visible:
		return
	var request: Dictionary = selection.choose(cell, session, actor, mode == &"target")
	match request.get("type", &""):
		&"select":
			actor = request.unit
			layer.get_view(actor.id).face_player()
			_resume_selection()
		&"context":
			_clear_selection()
			_open_actions()
		&"actions":
			_open_actions()
		&"restricted":
			_remind(request.action, actor.id)
		&"forecast":
			target_cell = cell
			mode = &"forecast"
			_set_overlay(true)
			forecast_panel.open(request.rows, npc_group)
		&"move":
			busy = true
			_lock_controls()
			await _play_movement(actor, session.move(actor, cell))
			busy = false
			_lock_controls()
			if not _show_result():
				_open_actions()

func _resume_selection() -> void:
	if actor == null or actor.current_hp <= 0 or actor.escaped:
		_clear_selection()
		return
	mode = &"move"
	movement_display.show_range(board, actor, session)
	board.queue_redraw()
	board.grab_focus()

func _open_actions() -> void:
	if actor != null and (actor.current_hp <= 0 or actor.escaped):
		_clear_selection()
	mode = &"actions"
	_set_overlay(true)
	var anchor: Rect2 = board.cell_rect(actor.cell if actor != null else board.selected)
	anchor.position += board.global_position
	var armed: bool = actor != null and session.battle.rules.weapon(actor) != null
	action_menu.open(actor, session.turns, armed, anchor)

func _choose_action(action: StringName) -> void:
	if action == &"wait" and actor != null and not session.permits(action, actor.id):
		_remind(action, actor.id)
		return
	_set_overlay(false)
	match action:
		&"save":
			save_and_return_requested.emit()
			return
		&"end_turn":
			await _end_turn()
			return
		&"move":
			_resume_selection()
			return
		&"items":
			if actor == null:
				return
			mode = &"items"
			_set_overlay(true)
			item_menu.open(actor, session.turns)
			return
		&"attack":
			if actor == null:
				return
			mode = &"target"
			movement_display.clear(board)
			board.attack_cells = session.attack_cells(actor)
		&"wait":
			if actor == null:
				return
			session.turns.wait_unit(actor)
			layer.get_view(actor.id).face_walk_direction()
			if session.turns.can_move(actor):
				_resume_selection()
			elif session.turns.can_act(actor):
				_open_actions()
			else:
				_clear_selection()
		&"cancel":
			_resume_selection()
	board.queue_redraw()
	board.grab_focus()

func _cancel() -> void:
	if mode == &"items":
		_open_actions()
		return
	if mode in [&"forecast", &"target", &"actions"]:
		_set_overlay(false)
		_resume_selection()
	else:
		_set_overlay(false)
		_clear_selection()
	board.grab_focus()
func _confirm_attack() -> void:
	if actor != null and not session.permits(&"attack", actor.id):
		_remind(&"attack", actor.id)
		return
	if busy:
		return
	busy = true
	_set_overlay(false)
	_lock_controls()
	await _play_attack(session.attack(actor, target_cell))
	busy = false
	_lock_controls()
	if not _show_result():
		if actor != null and session.turns.can_move(actor) and session.permits(&"move", actor.id):
			_resume_selection()
		else:
			_open_actions()

func _play_movement(unit: RefCounted, path: Array[Vector2i]) -> void:
	if not path.is_empty():
		await animations.move_unit(layer.get_view(unit.id), board, path)
		layer.refresh()
		board._select(unit.cell)

func _play_attack(result: Dictionary) -> void:
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
	await npc_turns.run(session, _play_movement, _play_attack, _update_phase, _run_events.bind("player_turn_started"))
	busy = false
	_lock_controls()
	if not _show_result():
		_update_phase()
		board.grab_focus()

func _show_result() -> bool:
	_update_objectives()
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
	if saved_campaign.get("map_state") is Dictionary:
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
		if not state_codec.restore_roster(session, saved_campaign.get("characters", {}), story, attribute_rules):
			load_error = state_codec.last_error
			return
		chapter_start = state_codec.capture(session, story)
	layer.refresh()
	_update_phase()
	if not session.outcome.is_empty():
		_show_result.call_deferred()

func capture_save() -> Dictionary:
	return state_codec.capture_progress(session, story, chapter_start, saved_campaign, chapter_info)

func _set_overlay(value: bool) -> void:
	overlay.visible = value
	action_menu.hide()
	forecast_panel.hide()
	item_menu.hide()
	$Interface/CompactCharacter.hide()
	_lock_controls()

func _lock_controls() -> void:
	board.input_enabled = not busy and not overlay.visible
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
	_update_objectives()

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
		"spawns": chapter_spawns, "moved": session.notify_moved, "evaluate_outcome": session.result}

func _run_events(trigger: String) -> void:
	var error: String = await events.dispatch(trigger, _story_context())
	layer.refresh()
	if not error.is_empty():
		message.text = error
func _layout_weather() -> void:
	var snow: Control = board.get_node("Snowfall")
	snow.visible = chapter_info.get("weather", "") == "snow"
	snow.get_node("Flakes").emitting = snow.visible
	snow.position = Vector2.ZERO
	snow.size = board.size

func _update_objectives() -> void:
	var progress: Dictionary = session.objective_progress()
	$Interface/WinPanel/Text.text = "VICTORY\n" + objective_text.format_group(progress.get("win", {}))
	$Interface/DefeatPanel/Text.text = "DEFEAT\n" + objective_text.format_group(progress.get("defeat", {}))