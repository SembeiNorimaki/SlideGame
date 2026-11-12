class_name Icons
extends RefCounted
## Small vector icons drawn with CanvasItem calls (no image assets needed).


## Padlock centered on `center`, roughly `s` pixels tall.
static func draw_lock(ci: CanvasItem, center: Vector2, s: float, color: Color) -> void:
	var body := Rect2(center.x - s * 0.5, center.y - s * 0.05, s, s * 0.7)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(s * 0.12))
	ci.draw_style_box(style, body)
	var r := s * 0.3
	var c := Vector2(center.x, body.position.y)
	var w := s * 0.12
	ci.draw_arc(c, r, PI, TAU, 24, color, w, true)
	ci.draw_line(c + Vector2(-r, 0), c + Vector2(-r, s * 0.05), color, w, true)
	ci.draw_line(c + Vector2(r, 0), c + Vector2(r, s * 0.05), color, w, true)


## Five-pointed star centered on `center` with outer radius `r`.
static func draw_star(ci: CanvasItem, center: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := deg_to_rad(-90.0 + i * 36.0)
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, color)
