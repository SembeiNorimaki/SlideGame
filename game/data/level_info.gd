class_name LevelInfo
extends RefCounted
## One entry of levels.json.

var number: int            ## 1-based level number (position in the file)
var atlas_coords: Vector2i ## cell in the shapes atlas: (column, row)
var solution: String


static func from_dict(p_number: int, d: Dictionary) -> LevelInfo:
	var info := LevelInfo.new()
	info.number = p_number
	var c: Array = d.get("atlas_coords", [0, 0])
	info.atlas_coords = Vector2i(int(c[0]), int(c[1]))
	info.solution = str(d.get("solution", ""))
	return info
