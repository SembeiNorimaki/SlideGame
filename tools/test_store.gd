extends Node
## Store / unlock smoke test (debug backend). Prints checks and saves
## screenshots of each step into the folder passed after "--".

var out: String
var main: Node


func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	print("backend = ", Store.Backend.keys()[Store.backend])
	Store.debug_reset()
	GameData.reset_progress()
	print("sets: ", GameData.sets.map(func(s): return "%s(%d levels, free=%s)" % [s.id, s.level_count(), s.free]))
	print("shapes level 3 solution = ", GameData.get_set("shapes").level(3).solution)
	main = load("res://game/main.tscn").instantiate()
	add_child(main)
	await _shot("1_menu_locked.png")
	print("buy button visible: ", main._current.get_node("%BuyButton").visible, " text: ", main._current.get_node("%BuyButton").text)

	main.show_set_select()
	await _shot("2_sets_locked.png")
	print("shapes unlocked before buying: ", GameData.is_unlocked(GameData.get_set("shapes")))

	# Tap the locked Shapes card -> purchase flow -> unlocked.
	var cards: Array = main._current.get_node("%List").get_children()
	cards[1].pressed.emit()
	await get_tree().create_timer(1.0).timeout
	await _shot("3_sets_unlocked.png")
	print("owns full game: ", GameData.owns_full_game(), "  shapes unlocked: ", GameData.is_unlocked(GameData.get_set("shapes")))

	main.show_main_menu()
	await _shot("4_menu_owned.png")
	print("buy button visible after purchase: ", main._current.get_node("%BuyButton").visible)

	# Cache: survives a reload, rejects a hand-edited value.
	Store._owned.clear()
	Store._load_cache()
	print("cache reload -> owned: ", Store.is_owned("full_game"))
	var cfg := ConfigFile.new()
	cfg.set_value("owned", "full_game", true)
	cfg.save(Store.CACHE_PATH)
	Store._owned.clear()
	Store._load_cache()
	print("hand-edited cache -> owned: ", Store.is_owned("full_game"))
	Store._owned["full_game"] = true
	Store._save_cache()

	main.start_level("shapes", 1)
	var play: Control = main._current
	await get_tree().process_frame
	play._tween.kill()
	play.get_node("%Shape").position.x = 232
	play.debug_see_through_covers = true
	await _shot("5_shapes_level1.png")

	Store.debug_reset()
	GameData.reset_progress()
	get_tree().quit()


func _shot(name: String) -> void:
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name))
