extends Node
## Autoload "GameData": loads the level definitions and the player's
## progress once, when the game starts.

const LEVELS_PATH := "res://game/data/levels.json"
const PROGRESS_PATH := "user://progress.json"

var levels: Array[LevelInfo] = []
var progress: LevelProgress


func _ready() -> void:
	levels = _load_levels(LEVELS_PATH)
	progress = LevelProgress.new(levels.size(), PROGRESS_PATH)


func level(number: int) -> LevelInfo:
	return levels[number - 1]


func level_count() -> int:
	return levels.size()


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
