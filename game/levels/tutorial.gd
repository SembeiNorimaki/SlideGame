extends LevelPlay
## Level 0: teaches how the game works. Each step lasts one pass of the shape:
##   1. see-through covers: "a shape slides behind two covers"
##   2. covers fade to solid: only the slit shows it
##   3. see-through again: so that's what the slit was showing
##   4. solid: your turn, type the answer
## Passing it unlocks level 1. Always uses the Easy speed and slit.

## Cover opacity while the covers are "see-through".
const SEE_THROUGH := 0.25
const STEPS := [
	{"text": "A shape slides behind two covers.", "alpha": SEE_THROUGH},
	{"text": "The covers hide everything except a thin slit in the middle. Watch it closely!", "alpha": 1.0},
	{"text": "Here it is again with see-through covers: the slit showed it one thin line at a time.", "alpha": SEE_THROUGH},
	{"text": "Your turn! What is the shape? Type it and press Submit.", "alpha": 1.0,
		"tip": "Tip: the button at the top turns the slit sideways."},
]

var step := -1
var _fade: Tween

@onready var _hint: Label = %Hint
@onready var _tip: Label = %Tip
@onready var _input_parts: Array[Control] = [$Layout/GuessArea, $Layout/SubmitArea]


func _ready() -> void:
	super()
	cover_alpha = STEPS[0].alpha
	_answer.set_editable(false)
	for part in _input_parts:
		part.modulate.a = 0.0
	slide_finished.connect(_next_step)
	_next_step()


func _apply_difficulty() -> void:
	# The tutorial should be easy whatever the Settings say.
	for d in GameData.DIFFICULTIES:
		if d.id == "easy":
			slide_duration *= d.duration_scale
			slit_width *= d.slit_scale


func _awards_stars() -> bool:
	return false


func _next_step() -> void:
	if step >= STEPS.size() - 1 or _solved:
		return
	step += 1
	var s: Dictionary = STEPS[step]
	_hint.text = s.text
	_tip.text = s.get("tip", "")
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
	_fade.tween_property(self, "cover_alpha", s.alpha, 0.8)
	_hint.modulate.a = 0.0
	_fade.tween_property(_hint, "modulate:a", 1.0, 0.5)
	if step == STEPS.size() - 1:
		for part in _input_parts:
			_fade.tween_property(part, "modulate:a", 1.0, 0.5)
		_answer.set_editable(true)
		_answer.focus_input()
