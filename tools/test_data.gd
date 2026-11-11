extends Node
## Smoke test for GameData: run as a scene, prints results, saves a screenshot of level 7.

func _ready() -> void:
	print("levels loaded: ", GameData.level_count())
	for n in [1, 7, 26]:
		var l := GameData.level(n)
		print("  level %d -> atlas_coords=%s solution=%s" % [n, l.atlas_coords, l.solution])
	var p := GameData.progress
	print("fresh: unlocked_up_to=", p.unlocked_up_to, " has_progress=", p.has_progress())
	p.complete_level(1)
	p.complete_level(2)
	print("after 1,2: unlocked_up_to=", p.unlocked_up_to, " completed=", p.completed_levels())
	var saved := FileAccess.get_file_as_string(p.save_path)
	print("progress.json first lines:\n", "\n".join(saved.split("\n").slice(0, 6)))
	# Reload from disk to prove it round-trips.
	var again := LevelProgress.new(GameData.level_count(), p.save_path)
	print("reloaded: completed=", again.completed_levels(), " unlocked_up_to=", again.unlocked_up_to)

	var play: Control = load("res://game/levels/level_play.tscn").instantiate()
	play.level = 7
	play.slide_duration = 1000.0
	add_child(play)
	for i in 3:
		await get_tree().process_frame
	play._tween.kill()
	play.get_node("%Shape").position.x = 232  # park it in the middle of the screen
	play.debug_see_through_covers = true
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	p.reset()
	get_tree().quit()
