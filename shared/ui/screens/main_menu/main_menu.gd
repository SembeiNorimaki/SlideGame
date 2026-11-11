class_name MainMenu
extends Control
## Generic main menu, reusable across games.
##
## The menu knows nothing about any specific game: it only shows buttons and
## emits signals. Each game instances this scene, sets the exported properties,
## and connects the signals to its own logic (load save, open settings, etc.).

signal new_game_requested
signal continue_requested
signal settings_requested
signal quit_requested

## Title shown at the top. Leave empty to use the project name.
@export var game_title: String = "":
	set(value):
		game_title = value
		_refresh()

## Small text under the buttons (e.g. "v0.1.0"). Empty hides it.
@export var footer_text: String = "":
	set(value):
		footer_text = value
		_refresh()

## Whether there is a saved game to continue.
@export var continue_available: bool = false:
	set(value):
		continue_available = value
		_refresh()

## If true, Continue is hidden when unavailable; otherwise it is shown greyed out.
@export var hide_continue_when_unavailable: bool = false:
	set(value):
		hide_continue_when_unavailable = value
		_refresh()

## Show the Settings button.
@export var show_settings: bool = true:
	set(value):
		show_settings = value
		_refresh()

## Show the Quit button. Automatically hidden on platforms where quitting
## isn't expected (iOS, Web).
@export var show_quit: bool = true:
	set(value):
		show_quit = value
		_refresh()

## If true and nothing is connected to quit_requested, Quit closes the app.
@export var quit_by_default: bool = true

@onready var _title: Label = %Title
@onready var _footer: Label = %Footer
@onready var _new_game: Button = %NewGameButton
@onready var _continue: Button = %ContinueButton
@onready var _settings: Button = %SettingsButton
@onready var _quit: Button = %QuitButton


func _ready() -> void:
	_new_game.pressed.connect(new_game_requested.emit)
	_continue.pressed.connect(continue_requested.emit)
	_settings.pressed.connect(settings_requested.emit)
	_quit.pressed.connect(_on_quit_pressed)
	_refresh()
	_focus_first_button.call_deferred()


func _refresh() -> void:
	if not is_node_ready():
		return
	_title.text = game_title if game_title != "" else str(ProjectSettings.get_setting("application/config/name"))
	_footer.text = footer_text
	_footer.visible = footer_text != ""
	_continue.disabled = not continue_available
	_continue.visible = continue_available or not hide_continue_when_unavailable
	_settings.visible = show_settings
	_quit.visible = show_quit and _platform_supports_quit()


func _focus_first_button() -> void:
	# Gives keyboard / gamepad / TV-remote users a starting point.
	# Skipped on touchscreens so phones don't show a focus ring on launch.
	if DisplayServer.is_touchscreen_available():
		return
	var first := _continue if continue_available else _new_game
	first.grab_focus()


func _on_quit_pressed() -> void:
	quit_requested.emit()
	if quit_by_default and quit_requested.get_connections().is_empty():
		get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back button / gesture
		_on_quit_pressed()


static func _platform_supports_quit() -> bool:
	return not (OS.has_feature("ios") or OS.has_feature("web"))
