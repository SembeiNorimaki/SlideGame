extends Node
## Scripted demo for recording: a level with the vertical slit, then the
## mode button switches to the horizontal slit.

func _ready() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_level("shapes", 2)
	var play: Control = main._current
	play.get_node("%AnswerInput").get_node("%Field").release_focus()
	await get_tree().create_timer(3.2).timeout
	play.get_node("%ModeButton").pressed.emit()
	await get_tree().create_timer(3.4).timeout
	get_tree().quit()
