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
		if vp:
			vp.size = entity.rect.size
			if entity.is_inside_tree():
				if entity.get_parent() != vp:
					entity.reparent(vp)
			else:
				vp.add_child(entity)
		entity.position = -entity.rect.position
## The [SubViewport] that contains the [Entity].
@export var vp: SubViewport


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
	texture.viewport_path = vp.get_path()
	if entity:
		# Run setter
		entity = entity
