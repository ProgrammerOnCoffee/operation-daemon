@abstract class_name Effect extends Resource
## An effect that's applied to a target every turn cycle.

# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

var effect_name :String: get = _get_effect_name
## The name of the effect. 
@abstract func _get_effect_name() -> String

var description :String: get = _get_description
## The description of the effect.
@abstract func _get_description() -> String

var target_type :Module.TARGET: get = _get_target_type
## Whether this effect is applied to the attacker or attackee
@abstract func _get_target_type() -> Module.TARGET

var base :float: get = _get_base
## The base value of the effect. Can be changed via Modifiers.
@abstract func _get_base() -> float 

var value:float
## The final value after all the modifiers are applied. Use this for apply_effect.

## Apply this effect to a target. Ran by that target.
@abstract func apply_effect(target:Node) -> bool
