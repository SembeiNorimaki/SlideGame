extends Node
## Autoload "GameData": loads every level set (sets.json + one levels file
## per set) and each set's progress when the game starts, and decides which
## sets are unlocked.

const SETS_PATH := "res://game/data/sets.json"

var sets: Array[GameSet] = []
## In-app product id of the "full game" unlock, as created in the Play Console.
var full_game_product_id := ""


func _ready() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(SETS_PATH))
	if not data is Dictionary or not data.get("sets") is Array:
		push_error("Invalid or missing %s" % SETS_PATH)
		return
	full_game_product_id = str(data.get("full_game_product_id", ""))
	for d in data["sets"]:
		sets.append(GameSet.from_dict(d))
	if full_game_product_id != "":
		Store.register_products([full_game_product_id])


func get_set(id: String) -> GameSet:
	for s in sets:
		if s.id == id:
			return s
	push_error("Unknown set: %s" % id)
	return null


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
