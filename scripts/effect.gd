@abstract
class_name Effect
extends Resource
## An effect that's applied to a target every turn cycle.

## The final [member base] of this [Effect] after all [Modifier]s have been
## applied. Use this value in [method apply_effect].
## [br]
## This is reset to [member base] each time the effect is parsed.
var modified_base: float

# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

## The name of the effect. 
var effect_name: String: get = _get_effect_name
@abstract func _get_effect_name() -> String

## The description of the effect.
var description: String: get = _get_description
@abstract func _get_description() -> String

## The color of the effect - applied as a modulate to enemies. 
var effect_color: Color: get = _get_effect_color
@abstract func _get_effect_color() -> Color

## Whether this effect is applied to the attacker or attackee
var target_type: Module.TARGET: get = _get_target_type
@abstract func _get_target_type() -> Module.TARGET

## The base value of the effect. Can be changed via Modifiers.
var base: float: get = _get_base
@abstract func _get_base() -> float 

## Apply this effect to a target. Ran by that target.
@abstract func apply_effect(target: Entity) -> bool
