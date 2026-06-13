@abstract class_name Modifier extends Resource
## A modifier for an effect - changes the value by a percentage.

# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

## The identifier for the effect. Used to apply effects.
var modification_type :String: get = _get_modification_type
@abstract func _get_modification_type() -> String

## The percentage change to apply to the effect's base, as a float. 0.9 = -10%.
var percent :float: get = _get_percent
@abstract func _get_percent() -> float
