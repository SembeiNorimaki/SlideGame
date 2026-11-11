class_name GuessInput
extends Control
## Word-guess input: one underscore per character of the solution
## (e.g. "sun" -> _ _ _). Typed characters appear on the underscores,
## Backspace/Delete removes the last one. Spaces in the solution are shown
## as gaps and don't need to be typed.
##
## Typing goes through a hidden LineEdit, so the phone's on-screen keyboard
## (including its delete key) works; a physical keyboard works too.
## Tap the slots to open the keyboard. Comparison is case-insensitive.

signal guess_changed(guess: String)
## Emitted when the keyboard's Enter / Done key is pressed.
signal submitted(guess: String)

@export var solution: String = "":
	set(value):
		solution = value
		_slot_count = _letters_of(value).length()
		if _line:
			_line.max_length = _slot_count
			_line.text = ""
		_update_min_size()
		queue_redraw()

@export_group("Look")
@export var font_size: int = 64
@export var slot_width: float = 72.0
@export var slot_gap: float = 18.0
## Extra space where the solution has a space between words.
@export var word_gap: float = 40.0
@export var underline_height: float = 6.0
@export var text_color: Color = Color(0.93, 0.94, 0.97)
@export var underline_color: Color = Color(0.45, 0.48, 0.58)
@export var cursor_color: Color = Color(0.96, 0.62, 0.24)
@export var correct_color: Color = Color(0.45, 0.9, 0.72)
@export var wrong_color: Color = Color(0.95, 0.38, 0.38)

enum Mood { NORMAL, CORRECT, WRONG }

var _slot_count := 0
var _line: LineEdit
var _mood := Mood.NORMAL
var _shake := 0.0:
	set(value):
		_shake = value
		queue_redraw()


func _ready() -> void:
	_line = LineEdit.new()
	_line.max_length = _slot_count
	_line.context_menu_enabled = false
	_line.selecting_enabled = false
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.modulate = Color.TRANSPARENT  # invisible, but still receives typing
	_line.size = Vector2(1, 1)
	_line.text_changed.connect(_on_text_changed)
	_line.text_submitted.connect(func(_t): submitted.emit(get_guess()))
	_line.focus_entered.connect(queue_redraw)
	_line.focus_exited.connect(queue_redraw)
	add_child(_line)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_update_min_size()


## Puts the cursor in the field (opens the on-screen keyboard on phones).
func focus_input() -> void:
	_line.grab_focus()
	_line.caret_column = _line.text.length()


func get_guess() -> String:
	return _line.text


func clear() -> void:
	_line.text = ""
	_set_mood(Mood.NORMAL)
	guess_changed.emit("")


func is_complete() -> bool:
	return _line.text.length() == _slot_count


func is_correct() -> bool:
	return _line.text.to_lower() == _letters_of(solution).to_lower()


## Visual feedback after a check: green when right; red + shake when wrong.
func show_result(correct: bool) -> void:
	_set_mood(Mood.CORRECT if correct else Mood.WRONG)
	if correct:
		_line.release_focus()
		_line.editable = false
	else:
		var t := create_tween()
		for x in [18.0, -14.0, 10.0, -6.0, 0.0]:
			t.tween_property(self, "_shake", x, 0.05)


func _on_text_changed(new_text: String) -> void:
	# Keep only letters/digits, never more than the number of slots.
	var clean := ""
	for ch in new_text:
		if _is_typeable(ch):
			clean += ch.to_upper()
	clean = clean.left(_slot_count)
	if clean != new_text:
		_line.text = clean
		_line.caret_column = clean.length()
	_set_mood(Mood.NORMAL)
	queue_redraw()
	guess_changed.emit(clean)


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if tapped and _line.editable:
		focus_input()
		accept_event()


func _set_mood(m: Mood) -> void:
	_mood = m
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var positions := _slot_positions()
	var typed := _line.text if _line else ""
	var line_y := size.y - underline_height
	for i in positions.size():
		var x: float = positions[i] + _shake
		var color := underline_color
		match _mood:
			Mood.CORRECT: color = correct_color
			Mood.WRONG: color = wrong_color
			_:
				if _line and _line.has_focus() and i == typed.length():
					color = cursor_color  # next slot to fill
		draw_rect(Rect2(x, line_y, slot_width, underline_height), color)
		if i < typed.length():
			var ch := typed[i]
			var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var baseline := line_y - 14.0
			var tc := text_color if _mood == Mood.NORMAL else color
			draw_string(font, Vector2(x + (slot_width - w) / 2.0, baseline), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tc)


## x of each slot's left edge, centered in the control, with word gaps.
func _slot_positions() -> Array[float]:
	var xs: Array[float] = []
	var x := 0.0
	var pending_gap := 0.0
	for ch in solution.strip_edges():
		if ch == " ":
			pending_gap = word_gap
			continue
		if not xs.is_empty():
			x += slot_gap + pending_gap
		xs.append(x)
		x += slot_width
		pending_gap = 0.0
	var offset := (size.x - x) / 2.0
	for i in xs.size():
		xs[i] += offset
	return xs


func _update_min_size() -> void:
	var words := solution.strip_edges().split(" ", false).size()
	var w := _slot_count * slot_width + maxi(_slot_count - 1, 0) * slot_gap + maxi(words - 1, 0) * word_gap
	custom_minimum_size = Vector2(w, font_size + 40.0)


static func _letters_of(s: String) -> String:
	return s.replace(" ", "")


static func _is_typeable(ch: String) -> bool:
	var c := ch.unicode_at(0)
	return (c >= 48 and c <= 57) or ch.to_lower() != ch.to_upper()
