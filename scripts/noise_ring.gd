extends Node2D
var radius: float = 100.0
var age: float = 0.0
var coin: bool = false
func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= 0.65:
		queue_free()
func _draw() -> void:
	draw_arc(Vector2.ZERO, radius * minf(age / 0.65, 1.0), 0, TAU, 48, Color(1, 0.85, 0.3, (1.0 - age / 0.65) * 0.55), 2.0)
	if coin:
		draw_circle(Vector2.ZERO, 5, Color(1, 0.8, 0.2))
