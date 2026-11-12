class_name GameSet
extends RefCounted
## One level set: an atlas of shapes plus its levels and the player's progress.

const CELL := Vector2i(64, 64)

var id: String
var title: String
## Free sets are always playable; the others need the full game.
var free: bool
var atlas: Texture2D
var levels: Array[LevelInfo] = []
var progress: LevelProgress


static func from_dict(d: Dictionary) -> GameSet:
	var s := GameSet.new()
	s.id = str(d.id)
	s.title = str(d.get("title", s.id))
	s.free = d.get("free", false) == true
	s.atlas = load(str(d.atlas))
	s.levels = _load_levels(str(d.levels))
	s.progress = LevelProgress.new(s.levels.size(), "user://progress_%s.json" % s.id)
	return s


func level(number: int) -> LevelInfo:
	return levels[number - 1]


func level_count() -> int:
	return levels.size()


## The level's shape, cut out of this set's atlas.
func texture_for(number: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = atlas
	tex.region = Rect2(Vector2(level(number).atlas_coords * CELL), Vector2(CELL))
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
