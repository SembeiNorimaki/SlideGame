class_name ConfirmDialog
extends CanvasLayer
## Modal yes/no dialog (scene: confirm_dialog.tscn). Easiest use:
##   if await ConfirmDialog.ask(self, "Reset all progress?", "...", "Reset"):
##       ...

signal closed(confirmed: bool)

const SCENE_PATH := "res://shared/ui/widgets/confirm_dialog/confirm_dialog.tscn"


## Shows the dialog on top of everything and waits for the answer.
static func ask(parent: Node, title: String, message: String, confirm_text: String, cancel_text: String = "Cancel") -> bool:
	var dialog: ConfirmDialog = load(SCENE_PATH).instantiate()
	parent.add_child(dialog)
	dialog.setup(title, message, confirm_text, cancel_text)
	var confirmed: bool = await dialog.closed
	dialog.queue_free()
	return confirmed


func setup(title: String, message: String, confirm_text: String, cancel_text: String) -> void:
	%Title.text = title
	%Message.text = message
	%Message.visible = message != ""
	%ConfirmButton.text = confirm_text
	%CancelButton.text = cancel_text


func _ready() -> void:
	%ConfirmButton.pressed.connect(_close.bind(true))
	%CancelButton.pressed.connect(_close.bind(false))
	%Dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close(false))
	if not DisplayServer.is_touchscreen_available():
		%CancelButton.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(false)


func _close(confirmed: bool) -> void:
	if not is_queued_for_deletion():
		closed.emit(confirmed)
