class_name SetSelect
extends Control
## Generic list of level sets ("packs"). Call set_entries() with one
## Dictionary per set: {id, title, subtitle, locked}.

signal set_selected(id: String)
## A locked set was tapped: a good moment to offer the unlock.
signal locked_set_selected(id: String)
signal back_requested

@export var title: String = "Choose a set":
	set(value):
		title = value
		if is_node_ready():
			%Title.text = value

var _entries: Array = []


func _ready() -> void:
	%Title.text = title
	%BackButton.pressed.connect(back_requested.emit)
	_rebuild()


func set_entries(entries: Array) -> void:
	_entries = entries
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	var list: VBoxContainer = %List
	for c in list.get_children():
		c.queue_free()
	var first: Button = null
	for e in _entries:
		var b := SetButton.new(e.get("title", ""), e.get("subtitle", ""), e.get("locked", false))
		if e.get("locked", false):
			b.pressed.connect(locked_set_selected.emit.bind(e.id))
		else:
			b.pressed.connect(set_selected.emit.bind(e.id))
		list.add_child(b)
		if first == null:
			first = b
	if first and not DisplayServer.is_touchscreen_available():
		first.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_requested.emit()
