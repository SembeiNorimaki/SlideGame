extends Control
## Play screen: the level's shape slides from off-screen right to off-screen left.

signal completed
signal exited
signal slide_finished

@export var level: int = 1
## Pause after a correct guess before leaving the level.
@export var success_delay: float = 1.8
## Seconds the shape takes to cross the whole screen.
@export var slide_duration: float = 3.0
## On-screen size of the shape (the source image is 64x64).
@export var shape_size: float = 256.0
## Restart the slide when it leaves the screen.
@export var loop: bool = true

@export_group("Covers")
## Width of the slit between the two covers, in screen pixels.
## The shape is drawn 4x (64 -> 256 px), so 4 px shows one image column.
@export var slit_width: float = 4.0:
	set(value):
		slit_width = value
		_layout_covers()
@export var cover_color: Color = Color(0.25, 0.27, 0.36):
	set(value):
		cover_color = value
		_layout_covers()
## Testing aid: makes the covers see-through so the hidden shape is visible.
@export var debug_see_through_covers: bool = true:
	set(value):
		debug_see_through_covers = value
		_layout_covers()

@onready var _shape: TextureRect = %Shape
@onready var _track: Control = %Track
@onready var _left_cover: ColorRect = %LeftCover
@onready var _right_cover: ColorRect = %RightCover
@onready var _guess: GuessInput = %GuessInput
@onready var _submit: Button = %SubmitButton
@onready var _feedback: Label = %Feedback
var _tween: Tween
var _solved := false


func _ready() -> void:
	%LevelLabel.text = "Level %d" % level
	%ExitButton.pressed.connect(exited.emit)
	var info := GameData.level(level)
	_shape.texture = ShapeAtlas.texture_at(info.atlas_coords)
	_guess.solution = info.solution
	_guess.guess_changed.connect(_on_guess_changed)
	_guess.submitted.connect(func(_g): submit())
	_submit.pressed.connect(submit)
	_on_guess_changed("")
	_shape.size = Vector2(shape_size, shape_size)
	_track.resized.connect(_layout_covers)
	_layout_covers()
	_start_slide.call_deferred()  # wait one frame so the track has its final size
	# Ready to type immediately: focus the first slot (opens the keyboard on phones).
	_guess.focus_input.call_deferred()


func _start_slide() -> void:
	var y := (_track.size.y - shape_size) / 2.0
	var start := Vector2(_track.size.x, y)   # just past the right edge
	var end := Vector2(-shape_size, y)       # just past the left edge
	_shape.position = start
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_shape, "position", end, slide_duration).from(start)
	_tween.finished.connect(_on_slide_finished)


## Two covers span the whole track, leaving only a vertical slit in the middle.
func _layout_covers() -> void:
	if not is_node_ready():
		return
	var mid := _track.size.x / 2.0
	var half := slit_width / 2.0
	_left_cover.position = Vector2.ZERO
	_left_cover.size = Vector2(mid - half, _track.size.y)
	_right_cover.position = Vector2(mid + half, 0.0)
	_right_cover.size = Vector2(_track.size.x - (mid + half), _track.size.y)
	var c := cover_color
	c.a = 0.6 if debug_see_through_covers else 1.0
	_left_cover.color = c
	_right_cover.color = c


## Compares the typed guess with the solution.
func submit() -> void:
	if _solved or not _guess.is_complete():
		return
	if _guess.is_correct():
		_on_solved()
	else:
		_guess.show_result(false)
		_feedback.text = "Not quite, try again"
		_feedback.modulate = _guess.wrong_color


func _on_guess_changed(_g: String) -> void:
	_submit.disabled = _solved or not _guess.is_complete()
	if not _solved:
		_feedback.text = ""


func _on_solved() -> void:
	_solved = true
	_submit.disabled = true
	_guess.show_result(true)
	_feedback.text = "Correct!"
	_feedback.modulate = _guess.correct_color
	# Reveal: stop the shape in the middle and fade the covers away.
	if _tween:
		_tween.kill()
	var center := (_track.size - _shape.size) / 2.0
	var reveal := create_tween().set_parallel()
	reveal.tween_property(_shape, "position", center, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal.tween_property(_left_cover, "modulate:a", 0.0, 0.5)
	reveal.tween_property(_right_cover, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(success_delay).timeout
	completed.emit()


func _on_slide_finished() -> void:
	slide_finished.emit()
	if loop and not _solved:
		_start_slide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		exited.emit()
