extends Node
## Scripted demo for recording: opens level 1, types a guess with real
## key events (including one typo + Backspace), clicks Submit,
## and lands on level 2 with its first slot already focused.

var main: Node


func _ready() -> void:
	GameData.reset_progress()
	main = load("res://game/main.tscn").instantiate()
	add_child(main)
	await _wait(0.1)
	main.start_level("letters", 1)
	var play: Control = main._current
	play.debug_see_through_covers = false  # real opaque covers
	await _wait(1.2)  # no tap needed: the first slot is focused on start
	await _type("b")
	await _wait(0.4)
	await _key(KEY_BACKSPACE, 0)
	await _wait(0.4)
	await _type("a")
	await _wait(0.8)
	await _click(play.get_node("%SubmitButton"))
	await _wait(3.0)  # success reveal, then back to level select
	get_tree().quit()


func _type(ch: String) -> void:
	await _key(OS.find_keycode_from_string(ch.to_upper()), ch.unicode_at(0))
	await _wait(0.35)


func _key(code: Key, unicode: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.unicode = unicode if pressed else 0
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame


func _click(control: Control) -> void:
	var pos := control.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	Input.parse_input_event(move)
	await _wait(0.15)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = pos
		e.global_position = pos
		e.pressed = pressed
		Input.parse_input_event(e)
		await _wait(0.12)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
