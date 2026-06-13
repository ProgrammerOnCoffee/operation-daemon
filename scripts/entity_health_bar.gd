extends Control
## A health bar displayed above an [Entity] during a fight.
##
## A health bar displayed above an [Entity] during a fight.

## The [Entity3D] to display this health bar above.
@export var entity_3d: Entity3D

@onready var cam := get_viewport().get_camera_3d()


func _ready() -> void:
	update()


func _draw() -> void:
	const COLOR = Color("#444457")
	var points := PackedVector2Array([
		Vector2(size.x / 2, 0),
		Vector2(size.x / 2, -16),
	])
	draw_circle(points[0] + Vector2(0, 4), 4, COLOR, false, 2.0, true)
	draw_polyline(points, COLOR, 2.0, true)
	draw_circle(points[-1], 3, COLOR, true, -1.0, true)


## Updates the position of the health bar, moving it above [member entity_3d].
func update() -> void:
	if cam and entity_3d:
		global_position = cam.unproject_position(
				entity_3d.project_point(Vector2(entity_3d.entity.rect.size.x / 2.0, 8))
		) - size / 2
