class_name LevelSelect
extends Control
## Generic level select grid, reusable across games.
##
## Levels are laid out row by row (1 2 3 4 / 5 6 7 8 / ...). The screen holds
## no save logic: call set_progress() (or use_progress() with a LevelProgress)
## and listen to level_selected / back_requested.

signal level_selected(level: int)
signal back_requested

@export var title: String = "Select Level":
	set(value):
		title = value
		_refresh_labels()

@export_range(1, 999) var level_count: int = 20:
	set(value):
		level_count = value
		_rebuild()

@export_range(1, 10) var columns: int = 4:
	set(value):
		columns = value
		if is_node_ready():
			_grid.columns = columns

@export var button_size: Vector2 = Vector2(132, 132):
	set(value):
		button_size = value
		_rebuild()

## Draw earned stars on completed levels (otherwise a check badge).
@export var show_stars: bool = false:
	set(value):
		show_stars = value
		_rebuild()

## Show "x / y completed" under the title.
@export var show_progress_text: bool = true:
	set(value):
		show_progress_text = value
		_refresh_labels()

var _unlocked_up_to: int = 1
var _completed: Dictionary = {}
var _stars: Dictionary = {}

@onready var _title: Label = %Title
@onready var _progress_label: Label = %ProgressLabel
@onready var _grid: GridContainer = %Grid
@onready var _back: Button = %BackButton


func _ready() -> void:
	_back.pressed.connect(back_requested.emit)
	_grid.columns = columns
	_rebuild()


## unlocked_up_to: highest playable level (1-based).
## completed_levels: level numbers already beaten.
## stars_by_level: {level: stars} (only used when show_stars is on).
func set_progress(unlocked_up_to: int, completed_levels: Array = [], stars_by_level: Dictionary = {}) -> void:
	_unlocked_up_to = unlocked_up_to
	_completed.clear()
	for level in completed_levels:
		_completed[int(level)] = true
	_stars = stars_by_level
	_rebuild()


## Convenience for games using the shared LevelProgress store.
func use_progress(progress: LevelProgress) -> void:
	level_count = progress.level_count
	set_progress(progress.unlocked_up_to, progress.completed_levels(), progress.stars_by_level())


func state_of(level: int) -> LevelButton.State:
	if _completed.has(level):
		return LevelButton.State.COMPLETED
	if level <= _unlocked_up_to:
		return LevelButton.State.AVAILABLE
	return LevelButton.State.LOCKED


func _rebuild() -> void:
	if not is_node_ready():
		return
	for child in _grid.get_children():
		child.queue_free()
	var focus_target: LevelButton = null
	for level in range(1, level_count + 1):
		var button := LevelButton.new(level, state_of(level), button_size)
		if show_stars:
			button.stars = _stars.get(level, 0)
		button.pressed.connect(level_selected.emit.bind(level))
		_grid.add_child(button)
		# Focus the next level to play (highest unlocked, not yet completed).
		if button.state == LevelButton.State.AVAILABLE or (focus_target == null and button.state == LevelButton.State.COMPLETED):
			focus_target = button
	_refresh_labels()
	if focus_target and not DisplayServer.is_touchscreen_available():
		focus_target.grab_focus.call_deferred()


func _refresh_labels() -> void:
	if not is_node_ready():
		return
	_title.text = title
	_progress_label.visible = show_progress_text
	_progress_label.text = tr("%d / %d completed") % [_completed.size(), level_count]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back button / gesture
		back_requested.emit()
