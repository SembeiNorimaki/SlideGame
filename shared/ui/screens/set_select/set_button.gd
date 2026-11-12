class_name SetButton
extends Button
## Wide card for one level set: title, a subtitle line (e.g. progress),
## and a padlock when the set is locked. Locked cards stay pressable so the
## game can offer to unlock them.

var title: String
var subtitle: String
var locked: bool


func _init(p_title: String, p_subtitle: String, p_locked: bool) -> void:
	title = p_title
	subtitle = p_subtitle
	locked = p_locked
	custom_minimum_size = Vector2(0, 168)
	focus_mode = Control.FOCUS_ALL
	tooltip_text = title


func _draw() -> void:
	var font := get_theme_default_font()
	var color := get_theme_color(&"font_color")
	var dim := color
	dim.a = 0.55
	var x := 40.0
	if locked:
		color.a = 0.6
	draw_string(font, Vector2(x, size.y * 0.48), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, color)
	draw_string(font, Vector2(x, size.y * 0.48 + 50), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, dim)
	if locked:
		Icons.draw_lock(self, Vector2(size.x - 80, size.y / 2.0), 52, dim)
