extends Node
## Scripted demo for recording: the whole tutorial, answered with "smiley".

func _ready() -> void:
	GameData.reset_progress()
	var main: Node = load("res://game/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_level("letters", 0)
	var tut: LevelPlay = main._current
	while tut.step < 3:
		await tut.slide_finished
	await get_tree().create_timer(2.0).timeout
	for ch in "smiley":
		var e := InputEventKey.new()
		e.keycode = OS.find_keycode_from_string(ch.to_upper())
		e.unicode = ch.unicode_at(0)
		e.pressed = true
		Input.parse_input_event(e)
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.5).timeout
	tut.get_node("%SubmitButton").pressed.emit()
	await get_tree().create_timer(3.5).timeout
	GameData.reset_progress()
	get_tree().quit()
