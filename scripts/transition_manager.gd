extends Node
## Handles transitions between [Control]s.
##
## Handles transitions between [Control]s.

## The amount by which bars' cutoffs will extend beyond the edge of the screen to
## account for when the rotated SCREEN_UV is outside of the [code]0-1[/code] range.
const CUTOFF_EXTEND = sqrt(2) - 1.0

## The base [ShaderMaterial] used for all transitions.
static var base_material := ShaderMaterial.new()

## The number of individual bars in the transition.
@export_range(1, 48, 1.0, "prefer_slider") var bar_count: int = 24
## If [code]true[/code], the transition bars will travel in random directions.
@export var random_directions: bool = true
## The duration of each individual bar's transition.
## The actual length of the transition is equivalent to [code]duration + spread[/code].
@export_range(0.0, 2.0, -1.0, "suffix:s") var duration: float = 0.5
## The delay, in seconds, between the start of the first bar's transition and the last bar's.
@export_range(0.0, 1.0, -1.0, "suffix:s") var spread: float = 0.25

@export_group("Angle", "angle")
## The minimum angle of the transition effect, in degrees.
## [code]0.0[/code] is equivalent to straight down.
@export_range(-360, 360, 1.0, "suffix:\u00b0") var angle_min: float = 105
## The minimum angle of the transition effect, in degrees.
## [code]0.0[/code] is equivalent to straight down.
@export_range(-360, 360, 1.0, "suffix:\u00b0") var angle_max: float = 255
## If [code]true[/code], the transition angle can be either positive or negative
## (i.e., it will have a range of [code]+-randf_range(angle_min, angle_max)[/code]).
@export var angle_negatable: bool = false

@export_group("Screen", "screen")
## The color of the intermediate screen transitioned to in [method transition_screen].
@export_color_no_alpha var screen_color := Color.BLACK
## If [code]true[/code], when using [method transition_screen], both the
## transtion to and from the monochrome screen will have the same angle
@export var screen_keep_angle: bool
## When using [method transition_screen], the delay between when the first
## transition to the monochrome screen ends and when the second transition from
## the monochrome screen begins.
## Set to a negative value to make the transition appear continuous.
@export_range(-2.0, 2.0, -1.0, "suffix:s") var screen_pause: float = 0.0

@export_group("Tween", "tween")
## The [enum Tween.EaseType] to use when transitioning.
@export var tween_ease: Tween.EaseType = Tween.EASE_IN_OUT
## The [enum Tween.TransitionType] to use when transitioning.
@export var tween_trans: Tween.TransitionType = Tween.TRANS_LINEAR

## A monochrome screen used in [method transition_screen].
var _screen := ColorRect.new()
## The angle of the previous transition effect.
var _last_angle: float


static func _static_init() -> void:
	base_material.shader = load("res://resources/transition.gdshader")
	## The cutoff for each transition bar.
	var cutoffs := PackedFloat32Array()
	cutoffs.resize(48)
	cutoffs.fill(-CUTOFF_EXTEND)
	base_material.set_shader_parameter(&"cutoffs", cutoffs)


func _init() -> void:
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.hide()
	add_child(_screen)


## Transitions between [param from] and [param to] at the same time. Best used
## to transition between multiple transparent screens, such as in the main menu.
## [br][br]
## Returns the transition's [signal Tween.finished] signal.
func transition(from: Control, to: Control) -> Signal:
	var mat := _create_material()
	
	## The cutoff for each transition bar.
	var cutoffs := mat.get_shader_parameter(&"cutoffs") as PackedFloat32Array
	## Sets cutoff [param index] in [member cutoffs] to [param value].
	var set_cutoff := func(value: float, index: int) -> void:
		cutoffs[index] = value
		mat.set_shader_parameter(&"cutoffs", cutoffs)
	
	var tween := create_tween().set_ease(tween_ease).set_trans(tween_trans).set_parallel()
	
	if from:
		from.material = mat
		from.set_instance_shader_parameter(&"inverted", false)
		from.show()
		tween.finished.connect(from.hide)
		tween.finished.connect(from.set.bind(&"material", null))
	
	if to:
		to.material = mat
		to.set_instance_shader_parameter(&"inverted", true)
		to.show()
		tween.finished.connect(to.set.bind(&"material", null))
	
	for i in bar_count:
		tween.tween_method(set_cutoff.bind(i), -CUTOFF_EXTEND, 1.0 + CUTOFF_EXTEND, duration).set_delay(randf() * spread)
	return tween.finished


## Transitions [param control] in or out of view, depending on [param fade_in].
## [br][br]
## Returns the transition's [signal Tween.finished] signal.
func fade(control: Control, fade_in: bool = false) -> Signal:
	return transition(null if fade_in else control, control if fade_in else null)


## Transitions between [param from] and [param to], showing a monochrome screen
## with color [member screen_color] in between.
## [br][br]
## Returns the transition's [signal Tween.finished] signal.
## [br][br]
## [b]Note:[/b] Using this method to transitioning between nodes that do not
## share the same parent may result in unpredictable behavior.
func transition_screen(from: Control, to: Control) -> Signal:
	if screen_keep_angle:
		_last_angle = 0.0
	_screen.color = screen_color
	_screen.reparent((from if from else to).get_parent())
	_screen.move_to_front()
	
	var last_signal: Signal
	if from:
		if screen_pause >= 0.0:
			last_signal = fade(_screen, true)
			await get_tree().create_timer(duration + spread + screen_pause).timeout
			from.hide()
		else:
			_screen.get_parent().move_child(_screen, from.get_index())
			_screen.show()
			last_signal = fade(from)
			await get_tree().create_timer(duration + spread + screen_pause).timeout
	if to:
		to.show()
		last_signal = fade(_screen)
	return last_signal


## Creates a new [ShaderMaterial] based on [member base_material].
func _create_material() -> ShaderMaterial:
	var mat := base_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter(&"bar_count", bar_count)
	
	# Scale UV based on window aspect ratio to prevent a skewing effect
	## The size of the game window.
	var window_size := get_window().size
	mat.set_shader_parameter(&"ratio", window_size.x / float(window_size.y))
	
	## The angle of the transition effect.
	var angle: float
	if screen_keep_angle and _last_angle:
		angle = _last_angle
	else:
		angle = deg_to_rad(randf_range(angle_min, angle_max))
		if angle_negatable:
			angle *= (+1 if randi_range(0, 1) else -1)
		_last_angle = angle if screen_keep_angle else 0.0
	mat.set_shader_parameter(&"angle", angle)
	
	## The direction of travel for each transition bar.
	var directions := PackedInt32Array()
	if random_directions:
		directions.resize(bar_count)
		for i in bar_count:
			directions[i] = randi_range(0, 1)
	mat.set_shader_parameter(&"directions", directions)
	return mat
