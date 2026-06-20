extends Control
## A health bar displayed above an [Entity] during a fight.
##
## A health bar displayed above an [Entity] during a fight.

## The [Entity3D] to display this health bar above.
@export var entity_3d: Entity3D

@onready var cam := get_viewport().get_camera_3d()


func _ready() -> void:
	RenderingServer.frame_pre_draw.connect(update)
	
	# Update the module bar. Doesn't change, so don't change.
	for module in entity_3d.entity.modules:
		var new_icon := Primitive2D.new()
		new_icon.filled = false
		
		new_icon.custom_minimum_size = Vector2.ONE * 25
		
		$ModuleBox.add_child(new_icon)
		
		
		if module.effects:
			new_icon.points = module.effects[0].icon_point_count
			new_icon.modulate = module.effects[0].effect_color
		else:
			new_icon.points = 1
			new_icon.modulate = Color.WHITE


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
		var hbarm := entity_3d.entity.get_node_or_null(^"HealthBarPoint") as Marker2D
		global_position = cam.unproject_position(
				entity_3d.project_point(Vector2(
						entity_3d.entity.rect.size.x / 2.0,
						(entity_3d.entity.rect.size.y + hbarm.position.y) if hbarm else 0.0
				))
		) - size / 2
