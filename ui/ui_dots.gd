class_name UiDots
extends RefCounted
## Coin-dot styleboxes shared by the HUD and the pause card: amber filled dot / hollow edge ring.

const AMBER := Color(0.961, 0.651, 0.137)
const EDGE := Color(0.357, 0.439, 0.565)

static var _full: StyleBoxFlat
static var _empty: StyleBoxFlat


static func full() -> StyleBoxFlat:
	if _full == null:
		_full = StyleBoxFlat.new()
		_full.bg_color = AMBER
		_full.set_corner_radius_all(6)
	return _full


static func empty() -> StyleBoxFlat:
	if _empty == null:
		_empty = StyleBoxFlat.new()
		_empty.draw_center = false
		_empty.border_color = EDGE
		_empty.set_border_width_all(2)
		_empty.set_corner_radius_all(6)
	return _empty


## Fills the first `count` dots, rings the rest.
static func apply(dots: Array[Panel], count: int) -> void:
	for i in dots.size():
		dots[i].add_theme_stylebox_override("panel", full() if i < count else empty())
