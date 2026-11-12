extends Control
## Play screen: the level's shape slides past a thin slit between two covers.
## Vertical slit: the shape moves right to left. Horizontal slit: top to bottom.
## The player can switch between them at any time with the mode button.

## stars: 1-3 earned for this solve (based on attempts), even if stars are hidden.
signal completed(stars: int)
signal exited
signal slide_finished

enum SlitMode { VERTICAL, HORIZONTAL }

## Which set (see sets.json) and which level in it.
@export var game_set_id: String = "letters"
@export var level: int = 1
## Pause after a correct guess before leaving the level.
@export var success_delay: float = 2.2
## Seconds the shape takes to cross the whole screen.
## Overridden by the difficulty chosen in Settings.
@export var slide_duration: float = 3.0
## On-screen size of the shape. Matches the atlas cell size (256) so it's drawn 1:1.
@export var shape_size: float = 256.0
## Restart the slide when it leaves the screen.
@export var loop: bool = true
## Slit direction the level starts with.
@export var mode: SlitMode = SlitMode.VERTICAL

@export_group("Covers")
## Width of the slit between the two covers, in screen pixels.
## Overridden by the difficulty chosen in Settings.
@export var slit_width: float = 4.0:
	set(value):
		slit_width = value
		_layout_covers()
@export var cover_color: Color = Color(0.25, 0.27, 0.36):
	set(value):
		cover_color = value
		_layout_covers()
## Testing aid: makes the covers see-through so the hidden shape is visible.
@export var debug_see_through_covers: bool = false:
	set(value):
		debug_see_through_covers = value
		_layout_covers()

@onready var _shape: TextureRect = %Shape
@onready var _track: Control = %Track
# Vertical mode: left and right of the slit. Horizontal mode: above and below it.
@onready var _cover_a: ColorRect = %CoverA
@onready var _cover_b: ColorRect = %CoverB
@onready var _mode_button: SlitModeButton = %ModeButton
@onready var _answer: AnswerInput = %AnswerInput
@onready var _submit: Button = %SubmitButton
@onready var _feedback: Label = %Feedback
@onready var _stars: StarsDisplay = %Stars
var _tween: Tween
var _solved := false
var _accepted := PackedStringArray()
## Answers submitted so far on this level (right or wrong).
var attempts := 0


func _ready() -> void:
	var game_set := GameData.get_set(game_set_id)
	%LevelLabel.text = "%s %d" % [tr(game_set.title), level]
	%ExitButton.pressed.connect(exited.emit)
	_shape.texture = game_set.texture_for(level)
	_accepted = GameData.answers(game_set, level)
	var difficulty := GameData.difficulty_params()
	slide_duration = difficulty.slide_duration
	slit_width = difficulty.slit_width
	_answer.text_changed.connect(_on_answer_changed)
	_answer.submitted.connect(func(_t): submit())
	_submit.pressed.connect(submit)
	_mode_button.pressed.connect(toggle_mode)
	_mode_button.mode = mode
	_on_answer_changed("")
	_shape.size = Vector2(shape_size, shape_size)
	_track.resized.connect(_layout_covers)
	_layout_covers()
	_start_slide.call_deferred()  # wait one frame so the track has its final size
	# Ready to type immediately (opens the keyboard on phones).
	_answer.focus_input.call_deferred()


## Switches between the vertical and horizontal slit and restarts the slide.
func toggle_mode() -> void:
	if _solved:
		return
	set_mode(SlitMode.HORIZONTAL if mode == SlitMode.VERTICAL else SlitMode.VERTICAL)


func set_mode(new_mode: SlitMode) -> void:
	mode = new_mode
	_mode_button.mode = mode
	_layout_covers()
	_start_slide()


func _start_slide() -> void:
	var t := _track.size
	var start: Vector2
	var end: Vector2
	if mode == SlitMode.VERTICAL:
		var y := (t.y - shape_size) / 2.0
		start = Vector2(t.x, y)            # just past the right edge
		end = Vector2(-shape_size, y)      # just past the left edge
	else:
		var x := (t.x - shape_size) / 2.0
		start = Vector2(x, -shape_size)    # just above the top edge
		end = Vector2(x, t.y)              # just below the bottom edge
	# Same speed in both modes (slide_duration is for the horizontal trip),
	# so the shape takes equally long to pass the slit either way.
	var speed := (t.x + shape_size) / slide_duration
	_shape.position = start
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_shape, "position", end, start.distance_to(end) / speed).from(start)
	_tween.finished.connect(_on_slide_finished)


## Two covers span the whole track, leaving only a thin slit through the middle.
func _layout_covers() -> void:
	if not is_node_ready():
		return
	var t := _track.size
	var half := slit_width / 2.0
	if mode == SlitMode.VERTICAL:
		var mid := t.x / 2.0
		_cover_a.position = Vector2.ZERO
		_cover_a.size = Vector2(mid - half, t.y)
		_cover_b.position = Vector2(mid + half, 0.0)
		_cover_b.size = Vector2(t.x - (mid + half), t.y)
	else:
		var mid := t.y / 2.0
		_cover_a.position = Vector2.ZERO
		_cover_a.size = Vector2(t.x, mid - half)
		_cover_b.position = Vector2(0.0, mid + half)
		_cover_b.size = Vector2(t.x, t.y - (mid + half))
	var c := cover_color
	c.a = 0.6 if debug_see_through_covers else 1.0
	_cover_a.color = c
	_cover_b.color = c


## Checks the typed answer against every accepted answer for the language.
func submit() -> void:
	if _solved or not _answer.has_text():
		return
	attempts += 1
	if AnswerMatcher.matches(_answer.get_text(), _accepted):
		_on_solved()
	else:
		_answer.show_result(false)
		_feedback.text = "Not quite, try again"
		_feedback.modulate = _answer.wrong_color


func _on_answer_changed(_t: String) -> void:
	_submit.disabled = _solved or not _answer.has_text()
	if not _solved:
		_feedback.text = ""


func _on_solved() -> void:
	_solved = true
	_submit.disabled = true
	_mode_button.disabled = true
	_answer.show_result(true)
	_feedback.text = "Correct!"
	_feedback.modulate = _answer.correct_color
	# Reveal: stop the shape in the middle and fade the covers away.
	if _tween:
		_tween.kill()
	var center := (_track.size - _shape.size) / 2.0
	var reveal := create_tween().set_parallel()
	reveal.tween_property(_shape, "position", center, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal.tween_property(_cover_a, "modulate:a", 0.0, 0.5)
	reveal.tween_property(_cover_b, "modulate:a", 0.0, 0.5)
	var stars := GameData.stars_for_attempts(attempts)
	if GameData.stars_enabled:
		_stars.pop_in(stars)
	await get_tree().create_timer(success_delay).timeout
	completed.emit(stars)


func _on_slide_finished() -> void:
	slide_finished.emit()
	if loop and not _solved:
		_start_slide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		exited.emit()
