@tool
class_name Primitive2D
extends Control

## The number of points in this primitive. Set to 1 for a circle.
@export_range(1, 8) var points: int = 3:
	set(value):
		points = value
		queue_redraw()
## If [code]true[/code], the drawn polygon will be filled.
@export var filled: bool = true:
	set(value):
		filled = value
		queue_redraw()


func _draw() -> void:
	custom_minimum_size.x = size.y
	## The distance that drawn primitives will be inset.
	const I = 4
	match points:
		1:
			draw_circle(size / 2, size.y / 2 - I * 1.5, Color.WHITE, filled, -1.0 if filled else size.y / 12, true)
		2:
			draw_line(Vector2(I * 2, size.y / 2), Vector2(size.x - I * 2, size.y / 2), Color.WHITE, size.y / 12, true)
		_:
			var polygon: PackedVector2Array
			polygon.resize(points)
			for i in points:
				polygon[i] = Vector2.UP.rotated(TAU / points * i) * (size.y / 2 - I - size.y / 24) + size / 2 + Vector2.DOWN * (21.0 / pow(points - 0.75, 2) if points % 2 == 1 else 0.0)
			if filled:
				draw_colored_polygon(polygon, Color.WHITE)
			# Draw polyline to antialias edges
			polygon.append(polygon[0])
			draw_polyline(polygon, Color.WHITE, size.y / 12, true)
