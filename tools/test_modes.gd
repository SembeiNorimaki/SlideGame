extends Node
## Smoke test: slit modes and the Symbols / Objects sets.

var out: String
var main: Node
var fails := 0


func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	Store.debug_reset()
	GameData.reset_progress()

	print("-- sets")
	_check(GameData.sets.map(func(s): return s.id) == ["letters", "shapes", "symbols", "objects"], "four sets in order")
	for s in GameData.sets:
		var missing := []
		for n in range(1, s.level_count() + 1):
			for lang in ["EN", "ES"]:
				if not s.level(n).solution.has(lang) or s.level(n).solution[lang].is_empty():
					missing.append("%d/%s" % [n, lang])
		_check(missing.is_empty(), "%s: %d levels, EN+ES answers for all %s" % [s.id, s.level_count(), missing])
	var symbols := GameData.get_set("symbols")
	var objects := GameData.get_set("objects")
	_check(AnswerMatcher.matches("arroba", symbols.level(4).answers("ES")), "symbols 4 (@): arroba")
	_check(AnswerMatcher.matches("At sign", symbols.level(4).answers("EN")), "symbols 4 (@): at sign")
	_check(AnswerMatcher.matches("avion", objects.level(2).answers("ES")), "objects 2 (plane): avion without accent")
	_check(not GameData.is_unlocked(symbols) and not GameData.is_unlocked(objects), "new sets locked without the full game")

	print("-- modes")
	main = load("res://game/main.tscn").instantiate()
	add_child(main)
	main.start_level("objects", 5)
	var play: Control = main._current
	await _frames(3)
	var track: Control = play.get_node("%Track")
	var a: ColorRect = play.get_node("%CoverA")
	_check(play.mode == 0 and a.size.y == track.size.y and a.size.x < track.size.x, "starts vertical: covers left/right")
	var x0: float = play.get_node("%Shape").position.x
	await _frames(10)
	_check(play.get_node("%Shape").position.x < x0, "vertical: shape moves left")
	play.get_node("%ModeButton").pressed.emit()
	await _frames(2)
	_check(play.mode == 1 and a.size.x == track.size.x and a.size.y < track.size.y, "after switch: covers above/below")
	var y0: float = play.get_node("%Shape").position.y
	_check(y0 < 0.0, "horizontal: restarts above the track")
	await _frames(10)
	_check(play.get_node("%Shape").position.y > y0, "horizontal: shape moves down")
	play.debug_see_through_covers = true
	await get_tree().create_timer(1.0).timeout
	await _shot("horizontal_see_through.png")
	play.debug_see_through_covers = false

	var field: LineEdit = play.get_node("%AnswerInput").get_node("%Field")
	field.text = "ancla"
	Settings.set_language("ES")
	play._accepted = GameData.answers(objects, 5)
	play.submit()
	await _frames(2)
	_check(play.get_node("%ModeButton").disabled, "mode button disabled once solved")
	Settings.set_language("EN")

	Store.buy(GameData.full_game_product_id)
	await get_tree().create_timer(1.0).timeout
	main.show_set_select()
	await _shot("set_select_4.png")
	Store.debug_reset()
	GameData.reset_progress()
	print("FAILED: %d" % fails if fails else "ALL PASSED")
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await _frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name))
