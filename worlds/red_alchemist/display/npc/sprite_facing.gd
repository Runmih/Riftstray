extends RefCounted

var textures: Dictionary = {}
var fallback: Texture2D
var direction: String = "south"
var walking_direction: String = "south"

func configure(sprite: Texture2D) -> void:
	fallback = sprite
	textures.clear()
	direction = "south"
	walking_direction = "south"
	if sprite == null:
		return
	var folder: String = sprite.resource_path.get_base_dir()
	for facing: String in ["south", "north", "west", "east"]:
		var path: String = folder.path_join(facing + ".png")
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path) as Texture2D
			if texture != null:
				textures[facing] = texture

func face(offset: Vector2, walking: bool = false) -> void:
	if offset.is_zero_approx():
		return
	if absf(offset.x) > absf(offset.y):
		direction = "east" if offset.x > 0 else "west"
	else:
		direction = "south" if offset.y > 0 else "north"
	if walking:
		walking_direction = direction

func texture() -> Texture2D:
	return textures.get(direction, fallback)