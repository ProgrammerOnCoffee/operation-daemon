@tool
extends ColorRect

## The percentage of the entity's remaining health.
@export_range(0, 1) var health_p: float = 1.0:
	set(value):
		if value > health_p:
			_shader_damaged_p = value
			fade_damaged_p()
		else:
			_tween().tween_property(self, ^":_shader_damaged_p", value, 0.1 + absf(_shader_damaged_p - value) * 0.15)
			_t_since_health_p_changed = 0.0
		health_p = value
## The delay after taking damage before the damaged portion of the health bar fades out.
@export var damaged_p_fade_delay: float = 4.0

## The current value of the bar's [member damaged_p] shader paramter.
var _shader_damaged_p: float = health_p:
	set(value):
		_shader_damaged_p = value
		set_instance_shader_parameter(&"damaged_p", _shader_damaged_p)
## The current value of the bar's [member health_p] shader paramter.
var _shader_health_p: float = health_p:
	set(value):
		_shader_health_p = maxf(value, _shader_damaged_p)
		set_instance_shader_parameter(&"health_p", _shader_health_p)
## The time since [member health_p] was last updated. Equal to [code]-1.0[/code]
## when [member _shader_health_p] and [member _shader_damaged_p] are equal (i.e.,
## when the damaged portion of the bar doesn't need to be hidden).
var _t_since_health_p_changed: float = -1.0


func _process(delta: float) -> void:
	if _t_since_health_p_changed >= 0.0:
		_t_since_health_p_changed += delta
		if _t_since_health_p_changed >= damaged_p_fade_delay:
			fade_damaged_p()


## Fades out the damaged portion of the health bar.
func fade_damaged_p() -> void:
	if _t_since_health_p_changed >= 0.0:
		_tween().tween_property(self, ^":_shader_health_p", _shader_damaged_p, 0.5 + absf(_shader_health_p - _shader_damaged_p) * 1.5)
		_t_since_health_p_changed = -1.0


## Creates a new [Tween].
func _tween() -> Tween:
	return create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


## Sets instance shader parameter [param param] to [param value].
func _set_param(value: float, param: StringName) -> void:
	set_instance_shader_parameter(param, value)


func _on_resized() -> void:
	_set_param(size.x, &"bar_width")
