class_name LevelButton
extends Button
## A square level tile: shows the number, a lock when locked, and when
## completed either its stars (if `stars` > 0) or a check badge. Styling comes
## from the theme variations "LevelButton" and "LevelButtonCompleted".

enum State { LOCKED, AVAILABLE, COMPLETED }

var level: int = 1
var state: State = State.LOCKED:
	set(value):
		state = value
		_apply_state()
## Stars earned (1-3) to draw on a completed level; 0 or less shows the check badge.
var stars: int = 0:
	set(value):
		stars = value
		_apply_state()


func _init(p_level: int = 1, p_state: State = State.LOCKED, p_size: Vector2 = Vector2(132, 132)) -> void:
	level = p_level
	custom_minimum_size = p_size
	focus_mode = Control.FOCUS_ALL
	state = p_state


func _apply_state() -> void:
	disabled = state == State.LOCKED
	# With stars the number is drawn by _draw(), a bit higher up.
	text = "" if state == State.LOCKED or _shows_stars() else str(level)
	theme_type_variation = &"LevelButtonCompleted" if state == State.COMPLETED else &"LevelButton"
	tooltip_text = "Level %d%s" % [level, " (locked)" if state == State.LOCKED else ""]
	queue_redraw()


func _draw() -> void:
	match state:
		State.LOCKED:
			Icons.draw_lock(self, size / 2.0, minf(size.x, size.y) * 0.34, get_theme_color(&"font_disabled_color"))
		State.COMPLETED:
			if _shows_stars():
				_draw_number_and_stars()
			else:
				var r := minf(size.x, size.y) * 0.13
				_draw_check(Vector2(size.x - r - 10.0, r + 10.0), r, get_theme_color(&"badge_color"))


func _shows_stars() -> bool:
	return state == State.COMPLETED and stars > 0


func _draw_number_and_stars() -> void:
	var font := get_theme_font(&"font")
	var fs := int(get_theme_font_size(&"font_size") * 0.85)
	var color := get_theme_color(&"font_color")
	var label := str(level)
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := size.y * 0.42 + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	draw_string(font, Vector2((size.x - w) / 2.0, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
	var r := size.x * 0.1
	var empty := color
	empty.a = 0.22
	for i in 3:
		var c := Vector2(size.x / 2.0 + (i - 1) * r * 2.3, size.y * 0.76)
		Icons.draw_star(self, c, r, get_theme_color(&"star_color") if i < stars else empty)


func _draw_check(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center, r, color, true, -1.0, true)
	var ink := Color(0.07, 0.2, 0.17)
	var pts := PackedVector2Array([
		center + Vector2(-0.45, 0.02) * r,
		center + Vector2(-0.12, 0.35) * r,
		center + Vector2(0.48, -0.3) * r,
	])
	draw_polyline(pts, ink, r * 0.28, true)
