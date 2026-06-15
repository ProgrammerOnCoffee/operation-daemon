@abstract class_name Modifier extends Resource
## A modifier for an effect - changes the value by a percentage.

# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

var effect_type :EffectType: get = _get_effect_type
## The type of the effect. Also used to apply effects.
@abstract func _get_effect_type() -> EffectType

var percent:float
## The percentage change to apply to the effect's base, as a float. 0.9 = -10%.
@abstract func _get_new_percent() -> float

## Whether this modifier is applied to the attacker or attackee. 
## Basically, whether it's positive or negative to have applied to yourself.
var target_type :Module.TARGET: get = _get_target_type
@abstract func _get_target_type() -> Module.TARGET

func _init() -> void:
	percent = _get_new_percent()
