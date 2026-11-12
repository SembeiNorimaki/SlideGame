extends Node
## Smoke test: answer matching, per-language answers, settings persistence,
## difficulty, and the settings / play screens (screenshots to the folder
## given after "--").

var out: String
var main: Node
var fails := 0


func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	var saved_language := Settings.language
	GameData.reset_progress()

	print("-- matching")
	_check(AnswerMatcher.matches("Water-Drop", ["drop", "water drop"]), "hyphen/case")
	_check(AnswerMatcher.matches("  waterdrop ", ["water drop"]), "spaces ignored")
	_check(AnswerMatcher.matches("corazon", ["corazón"]), "accent-insensitive")
	_check(AnswerMatcher.matches("CORAZÓN", ["corazón"]), "uppercase accent")
	_check(not AnswerMatcher.matches("pina", ["piña"]), "ñ stays distinct from n")
	_check(not AnswerMatcher.matches("", ["a"]), "empty never matches")
	_check(not AnswerMatcher.matches("drops", ["drop"]), "no partial match")

	print("-- languages")
	var shapes := GameData.get_set("shapes")
	var letters := GameData.get_set("letters")
	_check(letters.level(1).answers("EN") == PackedStringArray(["A"]), "letters level 1 is A")
	Settings.set_language("EN")
	_check(AnswerMatcher.matches("mug", GameData.answers(shapes, 16)), "EN: mug accepted for cup")
	_check(not AnswerMatcher.matches("taza", GameData.answers(shapes, 16)), "EN: taza rejected")
	_check(tr("Settings") == "Settings", "EN UI text")
	Settings.set_language("ES")
	_check(AnswerMatcher.matches("taza", GameData.answers(shapes, 16)), "ES: taza accepted")
	_check(AnswerMatcher.matches("relampago", GameData.answers(shapes, 19)), "ES: relampago accepted")
	_check(tr("Settings") == "Ajustes", "ES UI text")
	_check(letters.level(1).answers("FR") == PackedStringArray(["A"]), "unknown language falls back to EN")

	print("-- settings file")
	Settings.set_difficulty("hard")
	Settings.set_volume(0.35)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Settings.PATH))
	_check(saved.language == "ES" and saved.difficulty == "hard" and is_equal_approx(saved.volume, 0.35), "saved: %s" % saved)
	_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.35), "Master bus volume applied")

	print("-- screens")
	main = load("res://game/main.tscn").instantiate()
	add_child(main)
	main.show_settings()
	await _shot("settings_es.png")
	var reset_btn: Button = main._current.get_node("%ResetButton")
	reset_btn.pressed.emit()
	await _shot("settings_reset_dialog_es.png")
	var dialog: ConfirmDialog = main._current.get_children().filter(func(c): return c is ConfirmDialog)[0]
	dialog.get_node("%CancelButton").pressed.emit()

	Settings.set_language("EN")
	Settings.set_difficulty("easy")
	main.show_settings()
	await _shot("settings_en.png")

	Settings.set_difficulty("hard")
	main.start_level("shapes", 16)
	var play: Control = main._current
	await get_tree().process_frame
	_check(is_equal_approx(play.slide_duration, 3.0 * 0.67) and play.slit_width == 2.0, "hard difficulty applied to play screen")
	var field: LineEdit = play.get_node("%AnswerInput").get_node("%Field")
	_check(get_viewport().gui_get_focus_owner() == field, "answer field focused on start")
	play._tween.kill()
	play.get_node("%Shape").position.x = 232
	field.insert_text_at_caret("mug")
	await _shot("play_typed.png")
	play.get_node("%SubmitButton").pressed.emit()
	await _shot("play_correct.png")
	_check(play._solved, "'mug' solves the cup level")

	Settings.set_difficulty("normal")
	Settings.set_volume(0.8)
	Settings.set_language(saved_language)
	GameData.reset_progress()
	print("FAILED: %d" % fails if fails else "ALL PASSED")
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _shot(name: String) -> void:
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name))
