@tool
class_name Entity3D
extends Sprite3D
## Creates a 3D representation of a 2D [Entity].
##
## Creates a 3D representation of a 2D [Entity] with a [SubViewport].

## The pool of created [AudioStreamPlayer3D]s. Each value is whether or not it is in use.
static var audio_stream_player_pool: Dictionary[AudioStreamPlayer3D, bool]

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


## Removes [param asp] from the [SceneTree], resets it to its initial state,
## and updates [member audio_stream_player_pool] to reflect that the [param asp]
## is no longer being used.
static func _reset_asp(asp: AudioStreamPlayer3D) -> void:
	asp.get_parent().remove_child(asp)
	audio_stream_player_pool[asp] = false


func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS


func _ready() -> void:
	if not vp:
		vp = SubViewport.new()
		vp.name = &"SubViewport"
		vp.transparent_bg = true
		vp.size_2d_override_stretch = true
		vp.gui_snap_controls_to_pixels = false
		add_child(vp)
		vp.owner = owner
	if not texture:
		texture = vp.get_texture()
	if entity:
		# Run setter
		entity = entity


## Updates [member pixel_size] and [member vp]'s size according to [member resolution_scale].
func update_resolution() -> void:
	if vp and entity:
		entity.position = -entity.rect.position
		vp.size = entity.rect.size * resolution_scale
		vp.size_2d_override = entity.rect.size
		scale = Vector3.ONE / resolution_scale


## Plays a sound from [param bank].
func play_sound(bank: String, remaining_loop_count: int = -1) -> void:
	var asp: AudioStreamPlayer3D
	for player in audio_stream_player_pool:
		if not audio_stream_player_pool[player]:
			audio_stream_player_pool[player] = true
			asp = player
			break
	if not asp:
		asp = AudioStreamPlayer3D.new()
		asp.max_db = 0.0
		asp.autoplay = true
		asp.panning_strength = 0.5
		asp.bus = &"SFX"
		asp.attenuation_filter_cutoff_hz = 20500
		asp.finished.connect(_reset_asp.bind(asp))
		audio_stream_player_pool[asp] = true
	var sound = Entity.sounds[bank].pick_random()
	if sound is AudioStream:
		asp.stream = sound
	else:
		asp.stream = sound[0]
		if "loop_after" in sound[1] and "loop_count" in sound[1] and remaining_loop_count != 0:
			get_tree().create_timer(sound[1].loop_after).timeout.connect(play_sound.bind(bank,
					(remaining_loop_count if remaining_loop_count != -1 else sound[1].loop_count) - 1
			))
		if "next_sound" in sound[1]:
			get_tree().create_timer(sound[1].next_delay).timeout.connect(play_sound.bind(sound[1].next_sound))
		if "volume" in sound[1]:
			asp.volume_db = sound[1].volume
	asp.pitch_scale = randf_range(0.8, 1.1)
	add_child(asp)


## Moves this [Entity3D] beside [param to] to prepare for an attack.
func move_to_entity(to: Entity3D) -> void:
	play_sound(entity.sound_banks.dash)
	## The direction away from [param to] that this entity will be moved.
	var dir := Vector3.LEFT.rotated(Vector3.UP, entity.combat_handler.cam.rotation.y) * signf(to.global_position.x - global_position.x)
	entity.anim_player.play(entity.animation_names.dash, 0.2)
	await create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).tween_property(self, ^":global_position",
			to.initial_transform.origin * Vector3(1, 0, 1)
			# Keep player y position
			+ global_position * Vector3(0, 1, 0)
			# Move beside other entity
			+ dir * (
					(to.entity.rect.size.x / 2.0 - to.entity.rect_attack_inset) * to.pixel_size
					+ (entity.rect.size.x / 2.0 - entity.rect_attack_inset) * pixel_size
			), entity.animation_durations.dash).finished
	entity.anim_player.play(entity.animation_names.idle, 0.4)


## Returns this [Entity3D] to its initial [member global_transform].
func return_to_initial_transform() -> void:
	play_sound(entity.sound_banks.b_dash)
	entity.anim_player.play(entity.animation_names.b_dash, 0.2, 1.0, entity.animation_names.b_dash == entity.animation_names.dash and entity.animation_names.b_dash != "jump")
	create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).tween_property(
			self, ^":global_transform", initial_transform, entity.animation_durations.b_dash)
	await get_tree().create_timer(entity.animation_durations.b_dash - 0.3).timeout
	entity.anim_player.play(entity.animation_names.idle, 0.4)


## Returns the 3D point in world space that maps to the 2D coordinate [param p]
## in the [SubViewport] rect.
func project_point(p: Vector2) -> Vector3:
	p *= resolution_scale
	## The size of the viewport, in meters.
	var size := entity.rect.size * pixel_size
	## The global y rotation of this sprite.
	var rot := global_rotation.y
	if billboard:
		# Subtract angle from sprite to camera to rotation to account for billboard
		var camera := (
				Engine.get_singleton(&"EditorInterface").get_editor_viewport_3d() if Engine.is_editor_hint()
				else get_viewport()).get_camera_3d() as Camera3D
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
	var size := entity.rect.size * pixel_size
	## The global y rotation of this sprite.
	var rot := global_rotation.y
	if billboard:
		# Subtract angle from sprite to camera to rotation to account for billboard
		var camera := (
				Engine.get_singleton(&"EditorInterface").get_editor_viewport_3d() if Engine.is_editor_hint()
				else get_viewport()).get_camera_3d() as Camera3D
		rot -= Vector2(global_position.x, global_position.z).angle_to_point(
				Vector2(camera.global_position.x, camera.global_position.z)) - PI / 2
	## Half of [member size], rotated by [member rot].
	var hs_rot := Vector3(size.x / 2, size.y / 2, 0).rotated(Vector3.UP, rot)
	return Vector2(
		# Get percentage across vp.size [param p] is
		inverse_lerp(-hs_rot.x, +hs_rot.x, p.x - global_position.x),
		inverse_lerp(+hs_rot.y, -hs_rot.y, p.y - global_position.y),
	) * Vector2(vp.size) / resolution_scale
