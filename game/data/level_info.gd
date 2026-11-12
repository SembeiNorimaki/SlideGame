class_name LevelInfo
extends RefCounted
## One level of a set (an entry of game/data/sets/<set>.json):
##   {"atlas_coords": [col, row], "solution": {"EN": ["cup", "mug"], "ES": ["taza"]}}

## Used when a level has no answers for the current language.
const FALLBACK_LANGUAGE := "EN"

var number: int            ## 1-based level number (position in the file)
var atlas_coords: Vector2i ## cell in the shapes atlas: (column, row)
## Accepted answers per language code, e.g. {"EN": ["cup", "mug"], "ES": ["taza"]}.
var solution: Dictionary = {}


static func from_dict(p_number: int, d: Dictionary) -> LevelInfo:
	var info := LevelInfo.new()
	info.number = p_number
	var c: Array = d.get("atlas_coords", [0, 0])
	info.atlas_coords = Vector2i(int(c[0]), int(c[1]))
	var sol = d.get("solution", {})
	if sol is Dictionary:
		for lang in sol:
			var list = sol[lang]
			info.solution[str(lang).to_upper()] = PackedStringArray(list if list is Array else [str(list)])
	else:
		push_warning("Level %d: \"solution\" should be {\"EN\": [...], ...}" % p_number)
	return info


## Accepted answers in `language`, falling back to English.
func answers(language: String) -> PackedStringArray:
	if solution.has(language):
		return solution[language]
	return solution.get(FALLBACK_LANGUAGE, PackedStringArray())
