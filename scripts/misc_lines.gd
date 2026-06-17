@tool
extends Control

var p: float = randf_range(-l * 3, 1.0)
@onready var l: float = 0.3 - get_index() * 0.03
@onready var s: float = 1.0 + get_index() * 0.2


func _draw() -> void:
	draw_line(Vector2(size.x * p, size.y / 2), Vector2(size.x * p + size.x * l, size.y / 2), Color.WHITE, 2.5, false)


func _process(delta: float) -> void:
	p += delta * s / 20
	if p >= 1.0:
		p = -randf_range(l, l * 3)
	queue_redraw()
