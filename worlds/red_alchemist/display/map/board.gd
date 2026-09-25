extends Control

signal cell_selected(cell: Vector2i)
signal cell_activated(cell: Vector2i)
var input_enabled: bool = true
var attack_cells: Dictionary = {}
var escape_cells: Array[Vector2i] = []
signal cell_hovered(cell: Vector2i)
var _hovered := Vector2i(-1, -1)

var map_visual: Texture2D
var grid: RefCounted
var selected := Vector2i.ZERO
var _reachable: Dictionary = {}
var _path: Array[Vector2i] = []

func _ready() -> void:
	resized.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_entered.connect(func(): cell_selected.emit(selected))
	focus_exited.connect(_clear_hover)
	mouse_exited.connect(_clear_hover)
	focus_exited.connect(queue_redraw)

func configure(model: RefCounted, chapter_folder: String = "") -> void:
	grid = model
	map_visual = null
	if not chapter_folder.is_empty():
		var visual_path: String = chapter_folder.path_join("mapvisual.png")
		if ResourceLoader.exists(visual_path):
			map_visual = load(visual_path) as Texture2D
	queue_redraw()

func show_reachable(cells: Dictionary) -> void:
	_reachable = cells.duplicate()
	queue_redraw()

func show_path(cells: Array[Vector2i]) -> void:
	_path = cells.duplicate()
	queue_redraw()

func visual_rect() -> Rect2:
	var reference_size := Vector2(1024, 768)
	var scale_factor := maxf(size.x / reference_size.x, size.y / reference_size.y)
	var playable_size := Vector2(768, 480)
	scale_factor = minf(scale_factor, minf(size.x / playable_size.x, size.y / playable_size.y))
	var extent := reference_size * scale_factor
	return Rect2((size - extent) * 0.5, extent)

func _geometry() -> Rect2:
	if grid == null or grid.width == 0 or grid.height == 0:
		return Rect2()
	if map_visual != null:
		var image_area := visual_rect()
		return Rect2(image_area.position + image_area.size * Vector2(0.125, 0.1875), image_area.size * Vector2(0.75, 0.625))
	var tile_size := minf(size.x / grid.width, size.y / grid.height)
	var extent := Vector2(grid.width, grid.height) * tile_size
	return Rect2((size - extent) / 2.0, extent)

func _draw() -> void:
	var area := _geometry()
	if area.size.x <= 0:
		return
	if map_visual != null:
		draw_texture_rect(map_visual, visual_rect(), false)
	var tile_size: float = area.size.x / grid.width
	var font := ThemeDB.fallback_font
	var font_size := maxi(8, mini(16, int(tile_size / 5)))
	for cell: Vector2i in grid.tiles:
		var terrain: Resource = grid.terrain_at(cell)
		var rectangle := Rect2(area.position + Vector2(cell) * tile_size, Vector2.ONE * tile_size)
		if map_visual == null:
			draw_rect(rectangle.grow(-1), terrain.color)
			if terrain.texture != null:
				draw_texture_rect(terrain.texture, rectangle.grow(-1), false)
		if _reachable.has(cell):
			draw_rect(rectangle.grow(-2), Color(0.2, 0.55, 1.0, 0.28))
		if attack_cells.has(cell):
			draw_rect(rectangle.grow(-2), Color(1.0, 0.2, 0.2, 0.3))
		if escape_cells.has(cell):
			draw_rect(rectangle.grow(-2), Color(0.2, 0.65, 0.75, 0.26))
		var label: String = "EXIT" if escape_cells.has(cell) else (terrain.display_name if map_visual == null else "")
		while label.length() > 1 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > tile_size - 6:
			label = label.left(label.length() - 1)
		draw_string(font, rectangle.position + Vector2(3, tile_size * 0.55), label, HORIZONTAL_ALIGNMENT_CENTER, tile_size - 6, font_size, Color.WHITE)
	for column in range(grid.width + 1):
		var x: float = area.position.x + column * tile_size
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color(0.12, 0.18, 0.24, 0.14), 1.0)
	for row in range(grid.height + 1):
		var y: float = area.position.y + row * tile_size
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(0.12, 0.18, 0.24, 0.14), 1.0)
	draw_rect(area, Color(0.18, 0.25, 0.3, 0.48), false, 1.0)
	for index in range(1, _path.size()):
		var from := area.position + (Vector2(_path[index - 1]) + Vector2.ONE * 0.5) * tile_size
		var to := area.position + (Vector2(_path[index]) + Vector2.ONE * 0.5) * tile_size
		draw_line(from, to, Color(1, 0.85, 0.4), 3)
	if grid.contains(selected):
		draw_rect(Rect2(area.position + Vector2(selected) * tile_size, Vector2.ONE * tile_size).grow(-3), Color(1, 0.85, 0.4), false, 2)

func _gui_input(event: InputEvent) -> void:
	if grid == null or not input_enabled:
		return
	if event.is_action_pressed("ui_accept"):
		accept_event()
		cell_activated.emit(selected)
		return
	if event is InputEventMouseMotion:
		var hover_area := _geometry()
		var hover_cell := Vector2i(-1, -1)
		if hover_area.size.x > 0 and hover_area.has_point(event.position):
			var relative_hover: Vector2 = (event.position - hover_area.position) / (hover_area.size.x / grid.width)
			hover_cell = Vector2i(floori(relative_hover.x), floori(relative_hover.y))
		if hover_cell != _hovered:
			_hovered = hover_cell
			cell_hovered.emit(hover_cell)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var area := _geometry()
		if area.has_point(event.position) and area.size.x > 0:
			var relative: Vector2 = (event.position - area.position) / (area.size.x / grid.width)
			_select(Vector2i(floori(relative.x), floori(relative.y)))
			grab_focus()
			accept_event()
			cell_activated.emit(selected)
	var offset := Vector2i.ZERO
	if event.is_action_pressed("ui_left"):
		offset = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		offset = Vector2i.RIGHT
	elif event.is_action_pressed("ui_up"):
		offset = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		offset = Vector2i.DOWN
	if offset != Vector2i.ZERO:
		_select(selected + offset)
		accept_event()

func _select(cell: Vector2i) -> void:
	if grid.contains(cell):
		selected = cell
		cell_selected.emit(cell)
		queue_redraw()

func cell_rect(cell: Vector2i) -> Rect2:
	var area := _geometry()
	if grid == null or grid.width == 0:
		return Rect2()
	var tile_size: float = area.size.x / grid.width
	return Rect2(area.position + Vector2(cell) * tile_size, Vector2.ONE * tile_size)


func _clear_hover() -> void:
	_hovered = Vector2i(-1, -1)
	cell_hovered.emit(_hovered)




