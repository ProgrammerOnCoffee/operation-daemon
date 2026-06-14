@tool
class_name Entity3D
extends Sprite3D
## Creates a 3D representation of a 2D [Entity].
##
## Creates a 3D representation of a 2D [Entity] with a [SubViewport].


## The [Entity] that this sprite displays.
@export var entity: Entity:
	set(value):
		entity = value
		entity.entity_3d = self
		if vp:
			if entity.is_inside_tree():
				if entity.get_parent() != vp:
					entity.reparent(vp)
			else:
				vp.add_child(entity)
			update_resolution()
## The [SubViewport] that contains the [Entity].
@export var vp: SubViewport:
	set(value):
		vp = value
		update_resolution()
@export_range(0.5, 4.0, 0.125) var resolution_scale: float = 1.0:
	set(value):
		resolution_scale = value
		update_resolution()

## The initial transform of this [Entity3D] when the fight was loaded.
@onready var initial_transform := global_transform


func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS


func _ready() -> void:
	if not vp:
		vp = SubViewport.new()
		vp.name = &"SubViewport"
		vp.transparent_bg = true
		vp.gui_snap_controls_to_pixels = false
		add_child(vp)
		vp.owner = owner
	
	if not texture:
		texture = ViewportTexture.new()
	texture.viewport_path = (
			get_viewport().get_child(0).get_path_to(vp)
			if Engine.is_editor_hint() else vp.get_path())
	if entity:
		# Run setter
		entity = entity


## Updates [member pixel_size] and [member vp]'s size according to [member resolution_scale].
func update_resolution() -> void:
	if vp and entity:
		entity.scale = Vector2.ONE * resolution_scale
		entity.position = -entity.rect.position * resolution_scale
		vp.size = entity.rect.size * resolution_scale
	pixel_size = 0.01 / resolution_scale


## Moves this [Entity3D] beside [param to] to prepare for an attack.
func move_to_entity(to: Entity3D) -> void:
	var dir := global_position.direction_to(to.global_position)
	# Get camera angle in order to move player directly to the left of the enemy relative to the camera
	#var offset := Vector3.LEFT.rotated(Vector3.UP, entity.combat_handler.cam.rotation.y)
	dir = dir.rotated(Vector3.UP, entity.combat_handler.cam.rotation.y)
	dir = Vector3.LEFT.rotated(Vector3.UP, entity.combat_handler.cam.rotation.y) * signf(to.global_position.x - global_position.x)
	await create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).tween_property(self, ^":global_position",
			to.global_position * Vector3(1, 0, 1)
			# Keep player y position
			+ global_position * Vector3(0, 1, 0)
			# Move beside other entity
			+ dir * (
					# Entity viewport size + self viewport size
					to.vp.size.x * to.pixel_size
					+ vp.size.x * pixel_size
			) / 2, 0.8).finished


## Returns this [Entity3D] to its initial [member global_transform].
func return_to_initial_transform() -> void:
	await create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).tween_property(
			self, ^":global_transform", initial_transform, 0.8).finished


## Returns the 3D point in world space that maps to the 2D coordinate [param p]
## in the [SubViewport] rect.
func project_point(p: Vector2) -> Vector3:
	p *= resolution_scale
	## The size of the viewport, in meters.
	var size := vp.size * pixel_size
	## The global y rotation of this sprite.
	var rot := global_rotation.y
	if billboard:
		# Subtract angle from sprite to camera to rotation to account for billboard
		var camera := (
				EditorInterface.get_editor_viewport_3d() if Engine.is_editor_hint()
				else get_viewport()).get_camera_3d()
		rot -= Vector2(global_position.x, global_position.z).angle_to_point(
				Vector2(camera.global_position.x, camera.global_position.z)) - PI / 2
	## Half of [member size], rotated by [member rot].
	var hs_rot := Vector3(size.x / 2, size.y / 2, 0).rotated(Vector3.UP, rot)
	return global_position + Vector3(
		# Add rotated size based on percentage across vp.size [param p] is
		lerpf(-hs_rot.x, +hs_rot.x, p.x / vp.size.x),
		lerpf(+hs_rot.y, -hs_rot.y, p.y / vp.size.y),
		lerpf(-hs_rot.z, +hs_rot.z, p.x / vp.size.x),
	)


## Returns the 2D coordinate in the [SubViewport] rect that maps to the 3D point
## [param p] in world space.
func unproject_point(p: Vector3) -> Vector2:
	## The size of the viewport, in meters.
	var size := vp.size * pixel_size
	## The global y rotation of this sprite.
	var rot := global_rotation.y
	if billboard:
		# Subtract angle from sprite to camera to rotation to account for billboard
		var camera := (
				EditorInterface.get_editor_viewport_3d() if Engine.is_editor_hint()
				else get_viewport()).get_camera_3d()
		rot -= Vector2(global_position.x, global_position.z).angle_to_point(
				Vector2(camera.global_position.x, camera.global_position.z)) - PI / 2
	## Half of [member size], rotated by [member rot].
	var hs_rot := Vector3(size.x / 2, size.y / 2, 0).rotated(Vector3.UP, rot)
	return Vector2(
		# Get percentage across vp.size [param p] is
		inverse_lerp(-hs_rot.x, +hs_rot.x, p.x - global_position.x),
		inverse_lerp(+hs_rot.y, -hs_rot.y, p.y - global_position.y),
	) * Vector2(vp.size) / resolution_scale
