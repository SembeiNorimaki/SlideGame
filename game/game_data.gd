extends Node
## Autoload "GameData": loads every level set (sets.json + one levels file
## per set) and each set's progress when the game starts, decides which
## sets are unlocked, and maps settings (language, difficulty) to game values.

const SETS_PATH := "res://game/data/sets.json"
const CONFIG_PATH := "res://game/data/config.json"

## How hard a level is. Names are translation keys.
const DIFFICULTIES := [
	{"id": "easy", "name": "Easy", "slide_duration": 4.5, "slit_width": 8.0},
	{"id": "normal", "name": "Normal", "slide_duration": 3.0, "slit_width": 4.0},
	{"id": "hard", "name": "Hard", "slide_duration": 2.0, "slit_width": 2.0},
]

var sets: Array[GameSet] = []
## [{"id": "EN", "name": "English"}, ...] from sets.json.
var languages: Array = []
## In-app product id of the "full game" unlock, as created in the Play Console.
var full_game_product_id := ""

## From config.json: whether levels award stars, and how many attempts each needs.
var stars_enabled := false
var attempts_for_3_stars := 1
var attempts_for_2_stars := 3


func _ready() -> void:
	_load_config()
	var data = JSON.parse_string(FileAccess.get_file_as_string(SETS_PATH))
	if not data is Dictionary or not data.get("sets") is Array:
		push_error("Invalid or missing %s" % SETS_PATH)
		return
	full_game_product_id = str(data.get("full_game_product_id", ""))
	languages = data.get("languages", [{"id": "EN", "name": "English"}])
	Settings.set_supported_languages(PackedStringArray(languages.map(func(l): return l.id)))
	for d in data["sets"]:
		sets.append(GameSet.from_dict(d))
	if full_game_product_id != "":
		Store.register_products([full_game_product_id])


func _load_config() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not data is Dictionary:
		push_warning("Missing or invalid %s, using defaults" % CONFIG_PATH)
		return
	var stars: Dictionary = data.get("stars", {})
	stars_enabled = stars.get("enabled", false) == true
	attempts_for_3_stars = int(stars.get("attempts_for_3_stars", attempts_for_3_stars))
	attempts_for_2_stars = int(stars.get("attempts_for_2_stars", attempts_for_2_stars))


## Stars for solving a level after `attempts` submitted answers (1 = first try).
## Always at least 1: finishing a level is never worth nothing.
func stars_for_attempts(attempts: int) -> int:
	if attempts <= attempts_for_3_stars:
		return 3
	if attempts <= attempts_for_2_stars:
		return 2
	return 1


func get_set(id: String) -> GameSet:
	for s in sets:
		if s.id == id:
			return s
	push_error("Unknown set: %s" % id)
	return null


## Accepted answers for a level in the player's chosen language.
func answers(game_set: GameSet, level: int) -> PackedStringArray:
	return game_set.level(level).answers(Settings.language)


## Slide duration and slit width for the chosen difficulty.
func difficulty_params() -> Dictionary:
	for d in DIFFICULTIES:
		if d.id == Settings.difficulty:
			return d
	return DIFFICULTIES[1]


func owns_full_game() -> bool:
	return Store.is_owned(full_game_product_id)


func is_unlocked(game_set: GameSet) -> bool:
	return game_set.free or owns_full_game()


func has_progress() -> bool:
	for s in sets:
		if s.progress.has_progress():
			return true
	return false


func reset_progress() -> void:
	for s in sets:
		s.progress.reset()
