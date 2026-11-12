extends Node
## Smoke test: auto-focus on level start, and auto-advance to the next level.

func _ready() -> void:
	GameData.progress.reset()
	var main: Node = load("res://game/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_level(1)
	for i in 3:
		await get_tree().process_frame
	var owner := get_viewport().gui_get_focus_owner()
	print("level 1 focus owner: ", owner.get_class(), " inside GuessInput: ", owner.get_parent() is GuessInput)
	for ch in "hello":
		var e := InputEventKey.new()
		e.keycode = OS.find_keycode_from_string(ch.to_upper())
		e.unicode = ch.unicode_at(0)
		e.pressed = true
		Input.parse_input_event(e)
		await get_tree().process_frame
	main._current.get_node("%SubmitButton").pressed.emit()
	await get_tree().create_timer(main._current.success_delay + 0.3).timeout
	for i in 3:
		await get_tree().process_frame
	print("after win: current level = ", main._current.get("level"), "  completed = ", GameData.progress.completed_levels())
	owner = get_viewport().gui_get_focus_owner()
	print("level 2 focus owner: ", owner.get_class() if owner else "none", " inside GuessInput: ", owner != null and owner.get_parent() is GuessInput)
	main.start_level(26)
	main._on_level_completed(26)
	await get_tree().process_frame
	print("after last level: screen = ", main._current.name)
	GameData.progress.reset()
	get_tree().quit()
