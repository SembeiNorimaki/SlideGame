extends Node
## Game-specific glue: switches between screens. Data lives in GameData.
## The shared screens only emit signals; all decisions live here.

const MAIN_MENU := preload("res://shared/ui/screens/main_menu/main_menu.tscn")
const LEVEL_SELECT := preload("res://shared/ui/screens/level_select/level_select.tscn")
const LEVEL := preload("res://game/levels/level_play.tscn")

var progress: LevelProgress:
	get: return GameData.progress
var _current: Node


func _ready() -> void:
	show_main_menu()


func show_main_menu() -> void:
	var menu: MainMenu = MAIN_MENU.instantiate()
	menu.game_title = "My Game"
	menu.footer_text = "v0.1.0"
	menu.continue_available = progress.has_progress()
	menu.new_game_requested.connect(_on_new_game)
	menu.continue_requested.connect(show_level_select)
	menu.settings_requested.connect(func(): print("Settings"))  # TODO: settings screen
	_switch_to(menu)


func show_level_select() -> void:
	var select: LevelSelect = LEVEL_SELECT.instantiate()
	select.columns = 4
	_switch_to(select)
	select.use_progress(progress)
	select.level_selected.connect(start_level)
	select.back_requested.connect(show_main_menu)


func start_level(level: int) -> void:
	var scene := LEVEL.instantiate()
	scene.level = level
	scene.completed.connect(_on_level_completed.bind(level))
	scene.exited.connect(show_level_select)
	_switch_to(scene)


func _on_new_game() -> void:
	progress.reset()  # TODO: ask for confirmation if progress.has_progress()
	show_level_select()


func _on_level_completed(level: int) -> void:
	progress.complete_level(level)
	if level < GameData.level_count():
		start_level(level + 1)  # go straight on to the next level
	else:
		show_level_select()  # last level done  # TODO: an "all levels complete" screen


func _switch_to(screen: Node) -> void:
	if _current:
		_current.queue_free()
	_current = screen
	add_child(screen)
