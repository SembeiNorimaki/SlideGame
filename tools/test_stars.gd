extends Node
## Smoke test for stars: thresholds, attempts counting, best-of saving,
## old save files, and the screens with stars on and off.

var out: String
var main: Node
var fails := 0


func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	GameData.reset_progress()
	var letters := GameData.get_set("letters")

	print("-- config")
	_check(GameData.stars_enabled, "stars enabled in config.json")
	_check([1, 2, 3, 4, 9].map(GameData.stars_for_attempts) == [3, 2, 2, 1, 1], "1 try=3, 2-3 tries=2, more=1")

	print("-- playing")
	main = load("res://game/main.tscn").instantiate()
	add_child(main)
	main.start_level("letters", 1)
	await _frames(3)
	await _answer("x")
	await _answer("y")
	await _answer("a")  # 3rd attempt -> 2 stars
	await _shot("play_stars_2.png", 1.0)
	await get_tree().create_timer(1.5).timeout
	_check(letters.progress.stars_of(1) == 2, "level 1 saved with 2 stars (got %d)" % letters.progress.stars_of(1))
	_check(main._current.get("level") == 2, "moved on to level 2")
	await _answer("b")  # first try -> 3 stars
	await _shot("play_stars_3.png", 1.0)
	await get_tree().create_timer(1.5).timeout
	_check(letters.progress.stars_of(2) == 3, "level 2 saved with 3 stars")

	letters.progress.complete_level(2, 1)
	_check(letters.progress.stars_of(2) == 3, "worse replay keeps best (3)")
	letters.progress.complete_level(1, 3)
	_check(letters.progress.stars_of(1) == 3, "better replay raises to 3")
	letters.progress.complete_level(3, 1)
	letters.progress.complete_level(4, 2)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(letters.progress.save_path))
	_check(saved.levels[0] == {"completed": true, "stars": 3.0}, "saved format: %s" % saved.levels[0])

	print("-- old save file without stars")
	var f := FileAccess.open("user://progress_test_old.json", FileAccess.WRITE)
	f.store_string('{"levels": [{"completed": true}, {"completed": false}]}')
	f.close()
	var old := LevelProgress.new(26, "user://progress_test_old.json")
	_check(old.is_completed(1) and old.stars_of(1) == 0 and old.unlocked_up_to == 2, "loads: completed, 0 stars")
	DirAccess.remove_absolute("user://progress_test_old.json")

	print("-- screens")
	main.show_level_select("letters")
	await _shot("select_stars_on.png")
	GameData.stars_enabled = false
	main.show_level_select("letters")
	await _shot("select_stars_off.png")
	main.start_level("letters", 5)
	await _frames(3)
	await _answer("e")
	await _shot("play_stars_off.png", 1.0)
	_check(not main._current.get_node("%Stars").visible, "no stars shown when disabled")
	GameData.stars_enabled = true

	GameData.reset_progress()
	print("FAILED: %d" % fails if fails else "ALL PASSED")
	get_tree().quit()


func _answer(text: String) -> void:
	var play: Control = main._current
	var field: LineEdit = play.get_node("%AnswerInput").get_node("%Field")
	field.text = ""
	for ch in text:
		var e := InputEventKey.new()
		e.keycode = OS.find_keycode_from_string(ch.to_upper())
		e.unicode = ch.unicode_at(0)
		e.pressed = true
		Input.parse_input_event(e)
		await get_tree().process_frame
	play.get_node("%SubmitButton").pressed.emit()
	await _frames(2)


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
