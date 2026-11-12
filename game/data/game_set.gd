class_name GameSet
extends RefCounted
## One level set: an atlas of shapes plus its levels and the player's progress.

var id: String
var title: String
## Free sets are always playable; the others need the full game.
var free: bool
var atlas: Texture2D
## Size of one square image in the atlas, in pixels.
var cell_size: int = 256
var levels: Array[LevelInfo] = []
## Optional level 0 that teaches the game; it must be passed to unlock level 1.
## null when the set has no tutorial.
var tutorial: LevelInfo
var tutorial_texture: Texture2D
var progress: LevelProgress


static func from_dict(d: Dictionary) -> GameSet:
	var s := GameSet.new()
	s.id = str(d.id)
	s.title = str(d.get("title", s.id))
	s.free = d.get("free", false) == true
	s.atlas = load(str(d.atlas))
	s.cell_size = int(d.get("cell_size", 256))
	s.levels = _load_levels(str(d.levels))
	var tut = d.get("tutorial")
	if tut is Dictionary:
		s.tutorial = LevelInfo.from_dict(0, tut)
		s.tutorial_texture = load(str(tut.image))
	s.progress = LevelProgress.new(s.levels.size(), "user://progress_%s.json" % s.id, s.tutorial != null)
	return s


## Level 0 is the tutorial (if the set has one).
func level(number: int) -> LevelInfo:
	return tutorial if number == 0 else levels[number - 1]


func has_tutorial() -> bool:
	return tutorial != null


func level_count() -> int:
	return levels.size()


## The level's shape, cut out of this set's atlas.
func texture_for(number: int) -> Texture2D:
	if number == 0:
		return tutorial_texture
	var tex := AtlasTexture.new()
	tex.atlas = atlas
	tex.region = Rect2(Vector2(level(number).atlas_coords * cell_size), Vector2(cell_size, cell_size))
	return tex


static func _load_levels(path: String) -> Array[LevelInfo]:
	var result: Array[LevelInfo] = []
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("levels") is Array:
		push_error("Invalid or missing levels file: %s" % path)
		return result
	var i := 1
	for entry in data["levels"]:
		result.append(LevelInfo.from_dict(i, entry))
		i += 1
	return result
