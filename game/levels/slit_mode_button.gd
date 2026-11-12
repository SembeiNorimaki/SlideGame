class_name SlitModeButton
extends Button
## Square button showing the slit direction you switch to: a small box with
## a vertical or horizontal gap. Pressing it plays a quarter-turn animation.

var mode: int = 0:  ## LevelPlay.SlitMode of the current slit
	set(value):
		if value != mode and is_inside_tree():
			_spin = -PI / 2.0
			create_tween().tween_property(self, "_spin", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		mode = value
		queue_redraw()

var _spin := 0.0:
	set(value):
		_spin = value
		queue_redraw()


func _init() -> void:
	tooltip_text = "Switch slit direction"


func _draw() -> void:
	var color := get_theme_color(&"font_disabled_color" if disabled else &"font_color")
	var s := minf(size.x, size.y) * 0.5
	var box := Rect2(-s / 2.0, -s / 2.0, s, s)
	draw_set_transform(size / 2.0, _spin)
	var gap := s * 0.16
	# The icon shows the *other* direction: what pressing the button gives you.
	var vertical_icon := mode == 1
	if vertical_icon:
		var w := (s - gap) / 2.0
		draw_rect(Rect2(box.position, Vector2(w, s)), color)
		draw_rect(Rect2(box.position + Vector2(w + gap, 0), Vector2(w, s)), color)
	else:
		var h := (s - gap) / 2.0
		draw_rect(Rect2(box.position, Vector2(s, h)), color)
		draw_rect(Rect2(box.position + Vector2(0, h + gap), Vector2(s, h)), color)
	draw_set_transform(Vector2.ZERO)
