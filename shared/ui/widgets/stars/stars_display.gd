class_name StarsDisplay
extends Control
## A row of stars, e.g. 2 of 3 filled (scene: stars_display.tscn).
## pop_in() reveals them one by one with a small bounce.

@export_range(0, 10) var stars: int = 0:
	set(value):
		stars = value
		queue_redraw()
@export_range(1, 10) var max_stars: int = 3:
	set(value):
		max_stars = value
		_scales.resize(value)
		_scales.fill(1.0)
		_update_min_size()
		queue_redraw()
@export var star_radius: float = 34.0:
	set(value):
		star_radius = value
		_update_min_size()
		queue_redraw()
@export var spacing: float = 16.0
@export var filled_color: Color = Color(1, 0.8, 0.3)
@export var empty_color: Color = Color(1, 1, 1, 0.18)

var _scales: Array[float] = [1.0, 1.0, 1.0]


func _ready() -> void:
	_update_min_size()


## Shows `count` stars, popping each one in after the previous.
func pop_in(count: int) -> void:
	stars = count
	show()
	_scales.fill(0.0)
	var t := create_tween()
	for i in max_stars:
		t.tween_method(_set_scale.bind(i), 0.0, 1.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_scale(value: float, i: int) -> void:
	_scales[i] = value
	queue_redraw()


func _draw() -> void:
	var step := star_radius * 2.0 + spacing
	var x0 := (size.x - (max_stars * step - spacing)) / 2.0 + star_radius
	for i in max_stars:
		var c := Vector2(x0 + i * step, size.y / 2.0)
		Icons.draw_star(self, c, star_radius, empty_color)
		if i < stars and _scales[i] > 0.0:
			Icons.draw_star(self, c, star_radius * _scales[i], filled_color)


func _update_min_size() -> void:
	custom_minimum_size = Vector2(max_stars * (star_radius * 2.0 + spacing) - spacing, star_radius * 2.0)
