extends SceneTree
## Renders screens of the real game flow to PNGs.
## Usage: godot --path . -s res://tools/screenshot.gd -- <out_dir>

var out_dir: String


func _initialize() -> void:
	out_dir = OS.get_cmdline_user_args()[0]
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _frames()

	# Fresh game: only level 1 unlocked.
	main._on_new_game()
	await _shot("level_select_new.png")

	# Beat level 1 through the real flow: pick it, then win it.
	main.start_level(1)
	await _frames()
	main._current.completed.emit()
	await _shot("level_select_after_l1.png")
	print("after L1 -> unlocked_up_to=", main.progress.unlocked_up_to, " completed=", main.progress.completed.keys())

	# A few more levels, then replay level 2 (must stay completed, not re-lock anything).
	for l in [2, 3, 4, 5, 6, 7]:
		main._on_level_completed(l)
	main._on_level_completed(2)
	await _shot("level_select_progress.png")
	print("later  -> unlocked_up_to=", main.progress.unlocked_up_to, " completed=", main.progress.completed.keys())

	main.show_main_menu()
	await _shot("main_menu_continue.png")
	quit()


func _frames(n := 6) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name))
