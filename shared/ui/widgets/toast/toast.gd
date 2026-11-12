class_name Toast
extends CanvasLayer
## Short message that fades in near the bottom of the screen, then out.
## Add one to the scene tree and call show_message().

@export var duration: float = 2.4
## Distance from the bottom of the screen, in pixels.
@export var bottom_margin: float = 200.0

var _panel: PanelContainer
var _label: Label
var _tween: Tween


func _init() -> void:
	layer = 100


func _ready() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.set_corner_radius_all(16)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_panel.add_theme_stylebox_override(&"panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_size_override(&"font_size", 32)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)
	_panel.modulate.a = 0.0
	add_child(_panel)


func show_message(text: String) -> void:
	_label.text = text
	_panel.reset_size()
	var screen := get_viewport().get_visible_rect().size
	_panel.position = Vector2((screen.x - _panel.size.x) / 2.0, screen.y - bottom_margin - _panel.size.y)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_tween.tween_interval(duration)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.3)
