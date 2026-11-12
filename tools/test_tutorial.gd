extends Node
## Smoke test for the tutorial (level 0 of Letters).

var out: String
var main: Node
var fails := 0


func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	GameData.reset_progress()
	var letters := GameData.get_set("letters")
	var p := letters.progress

	print("-- fresh progress")
	_check(letters.has_tutorial() and not GameData.get_set("shapes").has_tutorial(), "Letters has a tutorial, Shapes doesn't")
	_check(p.is_unlocked(0) and not p.is_unlocked(1) and p.unlocked_up_to == 0, "only the tutorial is playable")
	_check(GameData.get_set("shapes").progress.is_unlocked(1), "sets without a tutorial start at level 1")

	main = load("res://game/main.tscn").instantiate()
	add_child(main)
	main.show_level_select("letters")
	await _frames(4)
	var grid: Array = main._current.get_node("%Grid").get_children()
	_check(grid[0].level == 0 and grid[0].state == LevelButton.State.AVAILABLE, "first tile is 0, playable")
	_check(grid[1].level == 1 and grid[1].state == LevelButton.State.LOCKED, "level 1 locked")
	await _shot("select_before.png")

	print("-- tutorial steps")
	Engine.time_scale = 3.0
	grid[0].pressed.emit()
	await _frames(3)
	var tut: LevelPlay = main._current
	var field: LineEdit = tut.get_node("%AnswerInput").get_node("%Field")
	var track_y: float = tut.get_node("%Track").global_position.y
	_check(tut.step == 0 and is_equal_approx(tut.cover_alpha, 0.25), "step 1: see-through covers")
	_check(not field.editable and tut.get_node("Layout/GuessArea").modulate.a == 0.0, "step 1: no input yet")
	_check(tut.get_node("%Hint").text == "A shape slides behind two covers.", "step 1 text")
	await tut.slide_finished
	await get_tree().create_timer(1.0).timeout
	_check(tut.step == 1 and is_equal_approx(tut.cover_alpha, 1.0), "step 2: covers solid")
	_check(tut.get_node("%Track").global_position.y == track_y, "step 2: slit area hasn't moved (3-line text)")
	await tut.slide_finished
	await get_tree().create_timer(1.0).timeout
	_check(tut.step == 2 and is_equal_approx(tut.cover_alpha, 0.25), "step 3: see-through again")
	await tut.slide_finished
	await get_tree().create_timer(1.0).timeout
	_check(tut.step == 3 and is_equal_approx(tut.cover_alpha, 1.0), "step 4: covers solid")
	_check(tut.get_node("%Track").global_position.y == track_y, "slit area doesn't move when the text changes")
	_check(field.editable and get_viewport().gui_get_focus_owner() == field, "step 4: input enabled and focused")
	await tut.slide_finished
	_check(tut.step == 3, "stays on step 4 until solved")
	Engine.time_scale = 1.0

	print("-- answering")
	await _type("sun")
	tut.get_node("%SubmitButton").pressed.emit()
	await _frames(2)
	_check(not tut._solved and tut.get_node("%Feedback").text == "Not quite, try again", "wrong answer rejected")
	field.text = ""
	await _type("Smiley")
	tut.get_node("%SubmitButton").pressed.emit()
	await _frames(2)
	_check(tut._solved and not tut.get_node("%Stars").visible, "smiley accepted, no stars")
	await _shot("tutorial_solved.png", 0.8)
	await get_tree().create_timer(2.0).timeout
	_check(p.tutorial_completed and p.is_unlocked(1), "tutorial saved, level 1 unlocked")
	_check(main._current.get("level") == 1, "went straight on to level 1")
	main.show_level_select("letters")
	await _frames(4)
	grid = main._current.get_node("%Grid").get_children()
	_check(grid[0].state == LevelButton.State.COMPLETED and grid[1].state == LevelButton.State.AVAILABLE, "tile 0 done, level 1 open")
	await _shot("select_after.png")

	print("-- saves")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(p.save_path))
	_check(saved.tutorial_completed == true, "progress file has tutorial_completed")
	var f := FileAccess.open("user://progress_test_old.json", FileAccess.WRITE)
	f.store_string('{"levels": [{"completed": true, "stars": 3}, {"completed": false}]}')
	f.close()
	var old := LevelProgress.new(26, "user://progress_test_old.json", true)
	_check(old.unlocked_up_to == 2, "old save with level 1 done: level 2 still unlocked")
	DirAccess.remove_absolute("user://progress_test_old.json")
	Settings.set_language("ES")
	_check(tr("A shape slides behind two covers.").begins_with("Una figura"), "Spanish tutorial text")
	Settings.set_language("EN")

	GameData.reset_progress()
	_check(not p.tutorial_completed, "reset progress also resets the tutorial")
	print("FAILED: %d" % fails if fails else "ALL PASSED")
	get_tree().quit()


func _type(text: String) -> void:
	for ch in text:
		var e := InputEventKey.new()
		e.keycode = OS.find_keycode_from_string(ch.to_upper())
		e.unicode = ch.unicode_at(0)
		e.pressed = true
		Input.parse_input_event(e)
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String, delay := 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	await _frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name))
