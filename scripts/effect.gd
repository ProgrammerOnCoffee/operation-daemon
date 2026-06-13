@abstract class_name Effect extends Resource
## An effect that's applied to a target every turn cycle.

# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

## The name of the effect.
var effect_name :String: get = _get_effect_name
@abstract func _get_effect_name() -> String
## The description of the effect.
var description :String: get = _get_description
@abstract func _get_description() -> String

## The identifier for the effect. Used to apply effects.
var modification_type :String: get = _get_modification_type
@abstract func _get_modification_type() -> String

## Whether this effect is applied to the attacker or attackee
var target_type :Module.TARGET: get = _get_target_type
@abstract func _get_target_type() -> Module.TARGET

## The base value of the effect. Can be changed via Modifiers.
var base :float: get = _get_base
@abstract func _get_base() -> float 

## The final value after all the modifiers are applied. Use this for apply_effect.
var value:float

## Apply this effect to a target. Ran by that target.
@abstract func apply_effect(target:Node) -> bool
