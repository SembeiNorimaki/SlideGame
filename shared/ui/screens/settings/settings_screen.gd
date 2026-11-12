class_name SettingsScreen
extends Control
## Generic settings screen: volume, language, difficulty, reset progress.
## Reads and writes the Settings autoload directly. The game supplies the
## choices with setup() and handles reset_progress_confirmed.

signal back_requested
## The player confirmed "Reset progress" in the dialog.
signal reset_progress_confirmed

var _languages: Array = []
var _difficulties: Array = []

@onready var _volume: HSlider = %VolumeSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _language: OptionButton = %LanguageOption
@onready var _difficulty_row: HBoxContainer = %DifficultyRow


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	%ResetButton.pressed.connect(_on_reset_pressed)
	_volume.value = Settings.volume * 100.0
	_volume_value.text = "%d%%" % roundi(_volume.value)
	_volume.value_changed.connect(_on_volume_changed)
	_language.item_selected.connect(func(i: int): Settings.set_language(_language.get_item_metadata(i)))
	_rebuild()


## languages / difficulties: [{"id": "EN", "name": "English"}, ...]
## Difficulty names are translation keys (e.g. "Easy"); language names are
## shown as written (each language in its own name).
func setup(languages: Array, difficulties: Array) -> void:
	_languages = languages
	_difficulties = difficulties
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	_language.clear()
	for i in _languages.size():
		_language.add_item(_languages[i].name)
		_language.set_item_metadata(i, _languages[i].id)
		if _languages[i].id == Settings.language:
			_language.select(i)
	%LanguageSection.visible = _languages.size() > 1

	for c in _difficulty_row.get_children():
		c.queue_free()
	var group := ButtonGroup.new()
	for d in _difficulties:
		var b := Button.new()
		b.text = d.name
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override(&"font_size", 34)
		b.button_pressed = d.id == Settings.difficulty
		b.pressed.connect(Settings.set_difficulty.bind(d.id))
		_difficulty_row.add_child(b)
	%DifficultySection.visible = not _difficulties.is_empty()


func _on_volume_changed(value: float) -> void:
	_volume_value.text = "%d%%" % roundi(value)
	Settings.set_volume(value / 100.0)


func _on_reset_pressed() -> void:
	var ok := await ConfirmDialog.ask(self, "Reset all progress?",
			"This deletes your progress in every set. Purchases are kept.", "Reset")
	if ok:
		reset_progress_confirmed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_requested.emit()
