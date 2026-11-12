extends Node
## Autoload "Settings": the player's preferences, saved to user://settings.json.
## Reusable across games: volume drives the Master audio bus, language drives
## the UI translation locale, difficulty is an id whose meaning each game defines.

signal changed(key: String)

const PATH := "user://settings.json"

## 0.0 (mute) to 1.0.
var volume: float = 0.8
## Language id such as "EN" or "ES". Set on first launch from the phone's language.
var language: String = ""
var difficulty: String = "normal"

var _supported_languages := PackedStringArray()


func _ready() -> void:
	_load()
	_apply_volume()


## Called once by the game with the language ids it supports. Picks the
## phone's language on first launch, or `fallback` if it isn't supported.
func set_supported_languages(ids: PackedStringArray, fallback: String = "EN") -> void:
	_supported_languages = ids
	if not ids.has(language):
		var phone := OS.get_locale_language().to_upper()
		language = phone if ids.has(phone) else fallback
		_save()
	_apply_language()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save()
	changed.emit("volume")


func set_language(id: String) -> void:
	if id == language or (not _supported_languages.is_empty() and not _supported_languages.has(id)):
		return
	language = id
	_apply_language()
	_save()
	changed.emit("language")


func set_difficulty(id: String) -> void:
	if id == difficulty:
		return
	difficulty = id
	_save()
	changed.emit("difficulty")


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))


func _apply_language() -> void:
	TranslationServer.set_locale(language.to_lower())


func _load() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
	if not data is Dictionary:
		return
	volume = clampf(float(data.get("volume", volume)), 0.0, 1.0)
	language = str(data.get("language", language))
	difficulty = str(data.get("difficulty", difficulty))


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Can't write %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify({"volume": volume, "language": language, "difficulty": difficulty}, "  "))
