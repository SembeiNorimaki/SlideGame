class_name LevelButton
extends Button
## A square level tile: shows the number, a lock when locked,
## and a check badge when completed. Styling comes from the theme
## variations "LevelButton" and "LevelButtonCompleted".

enum State { LOCKED, AVAILABLE, COMPLETED }

var level: int = 1
var state: State = State.LOCKED:
	set(value):
		state = value
		_apply_state()


func _init(p_level: int = 1, p_state: State = State.LOCKED, p_size: Vector2 = Vector2(132, 132)) -> void:
	level = p_level
	custom_minimum_size = p_size
	focus_mode = Control.FOCUS_ALL
	state = p_state


func _apply_state() -> void:
	disabled = state == State.LOCKED
	text = "" if state == State.LOCKED else str(level)
	theme_type_variation = &"LevelButtonCompleted" if state == State.COMPLETED else &"LevelButton"
	tooltip_text = "Level %d%s" % [level, " (locked)" if state == State.LOCKED else ""]
	queue_redraw()


func _draw() -> void:
	match state:
		State.LOCKED:
			Icons.draw_lock(self, size / 2.0, minf(size.x, size.y) * 0.34, get_theme_color(&"font_disabled_color"))
		State.COMPLETED:
			var r := minf(size.x, size.y) * 0.13
			_draw_check(Vector2(size.x - r - 10.0, r + 10.0), r, get_theme_color(&"badge_color"))


func _draw_check(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center, r, color, true, -1.0, true)
	var ink := Color(0.07, 0.2, 0.17)
	var pts := PackedVector2Array([
		center + Vector2(-0.45, 0.02) * r,
		center + Vector2(-0.12, 0.35) * r,
		center + Vector2(0.48, -0.3) * r,
	])
	draw_polyline(pts, ink, r * 0.28, true)
