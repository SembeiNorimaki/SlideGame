class_name AnswerInput
extends Control
## Single free-text answer field (scene: answer_input.tscn). Gives no hint
## about the answer's length, so several different words can be accepted.
## Focusing it opens the on-screen keyboard on phones; the keyboard's
## Enter/Done key emits `submitted`. Checking the answer is up to the caller
## (see AnswerMatcher); show_result() gives the visual feedback.

signal text_changed(text: String)
signal submitted(text: String)

@export var max_length: int = 24:
	set(value):
		max_length = value
		if is_node_ready():
			_field.max_length = value

@export_group("Colors")
@export var text_color: Color = Color(0.93, 0.94, 0.97)
@export var underline_color: Color = Color(0.45, 0.48, 0.58)
@export var focus_color: Color = Color(0.96, 0.62, 0.24)
@export var correct_color: Color = Color(0.45, 0.9, 0.72)
@export var wrong_color: Color = Color(0.95, 0.38, 0.38)

@onready var _field: LineEdit = %Field
var _shake_tween: Tween
var _placeholder: String
## Text at the moment show_result() was called; null when there's no result showing.
var _result_text = null


func _ready() -> void:
	_field.max_length = max_length
	_field.text_changed.connect(_on_text_changed)
	_field.text_submitted.connect(func(t: String): submitted.emit(t))
	# The hint only shows while the field has no cursor; a centered caret
	# would otherwise blink in the middle of it.
	_placeholder = _field.placeholder_text
	_field.focus_entered.connect(func(): _field.placeholder_text = "")
	_field.focus_exited.connect(func(): _field.placeholder_text = _placeholder)
	_set_colors(underline_color, focus_color, text_color)


## Puts the cursor in the field (opens the on-screen keyboard on phones).
func focus_input() -> void:
	if not _field.editable:
		return
	_field.grab_focus()
	_field.caret_column = _field.text.length()


func get_text() -> String:
	return _field.text


func has_text() -> bool:
	return not _field.text.strip_edges().is_empty()


func clear() -> void:
	_field.text = ""
	_result_text = null
	_on_text_changed("")


## Green and locked when right; red + shake when wrong (text stays editable).
func show_result(correct: bool) -> void:
	_result_text = _field.text
	if correct:
		_set_colors(correct_color, correct_color, correct_color)
		_field.editable = false
		_field.release_focus()
		return
	_set_colors(wrong_color, wrong_color, wrong_color)
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for x in [18.0, -14.0, 10.0, -6.0, 0.0]:
		_shake_tween.tween_property(_field, "position:x", x, 0.05)
	focus_input()


func _on_text_changed(new_text: String) -> void:
	# LineEdit reports typing at the end of the frame, so the report for the
	# last keystroke can arrive after the answer was already checked. Ignore it
	# while the text is still the one that was checked.
	if _result_text != null and new_text == _result_text:
		return
	_result_text = null
	_set_colors(underline_color, focus_color, text_color)  # back to normal after a wrong guess
	text_changed.emit(new_text)


func _set_colors(line: Color, line_focused: Color, font: Color) -> void:
	for state in [&"normal", &"read_only"]:
		var sb: StyleBoxFlat = _field.get_theme_stylebox(state).duplicate()
		sb.border_color = line
		_field.add_theme_stylebox_override(state, sb)
	var focus: StyleBoxFlat = _field.get_theme_stylebox(&"focus").duplicate()
	focus.border_color = line_focused
	_field.add_theme_stylebox_override(&"focus", focus)
	_field.add_theme_color_override(&"font_color", font)
	_field.add_theme_color_override(&"font_uneditable_color", font)
