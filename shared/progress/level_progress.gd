class_name LevelProgress
extends RefCounted
## Reusable linear level progression, saved as JSON:
##   {"levels": [{"completed": true, "stars": 3}, {"completed": false, "stars": 0}, ...]}
## Entry i is level i + 1. Level 1 is always unlocked; completing level N
## unlocks level N + 1. Completed levels stay playable for replays; a replay
## only ever raises a level's stars (best result is kept).

var save_path: String
var level_count: int
## Highest playable level (1-based), derived from what's completed.
var unlocked_up_to: int:
	get:
		var highest := 0
		for i in _completed.size():
			if _completed[i]:
				highest = i + 1
		return clampi(highest + 1, 1, level_count)

var _completed: Array[bool] = []
var _stars: Array[int] = []


func _init(p_level_count: int, p_save_path: String = "user://progress.json") -> void:
	level_count = p_level_count
	save_path = p_save_path
	_completed.resize(level_count)
	_completed.fill(false)
	_stars.resize(level_count)
	_stars.fill(0)
	if FileAccess.file_exists(save_path):
		load_from_disk()
	else:
		save_to_disk()  # create the file with every level not completed


func is_unlocked(level: int) -> bool:
	return level >= 1 and level <= unlocked_up_to


func is_completed(level: int) -> bool:
	return level >= 1 and level <= level_count and _completed[level - 1]


## Level numbers (1-based) that have been completed.
func completed_levels() -> Array[int]:
	var out: Array[int] = []
	for i in _completed.size():
		if _completed[i]:
			out.append(i + 1)
	return out


## Best stars earned on a level (0 = none yet).
func stars_of(level: int) -> int:
	return _stars[level - 1] if level >= 1 and level <= level_count else 0


## {level number: stars} for every completed level.
func stars_by_level() -> Dictionary:
	var out := {}
	for i in _completed.size():
		if _completed[i]:
			out[i + 1] = _stars[i]
	return out


func total_stars() -> int:
	var total := 0
	for st in _stars:
		total += st
	return total


func completed_count() -> int:
	return _completed.count(true)


func has_progress() -> bool:
	return _completed.has(true)


func complete_level(level: int, stars: int = 0) -> void:
	_completed[level - 1] = true
	_stars[level - 1] = maxi(_stars[level - 1], stars)
	save_to_disk()


func reset() -> void:
	_completed.fill(false)
	_stars.fill(0)
	save_to_disk()


func load_from_disk() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary or not data.get("levels") is Array:
		push_warning("Progress file unreadable, starting fresh: %s" % save_path)
		return
	var entries: Array = data["levels"]
	# Tolerates a file from an older version with fewer/more levels.
	for i in mini(entries.size(), level_count):
		var e = entries[i]
		if e is Dictionary:
			_completed[i] = e.get("completed", false) == true
			_stars[i] = clampi(int(e.get("stars", 0)), 0, 3)


func save_to_disk() -> void:
	var entries := []
	for i in _completed.size():
		entries.append({"completed": _completed[i], "stars": _stars[i]})
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Can't write progress file %s: %s" % [save_path, error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify({"levels": entries}, "  "))
