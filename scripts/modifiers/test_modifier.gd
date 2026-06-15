class_name TestModifier extends Modifier
## A test modifier that returns random values.

func _get_effect_type() -> EffectType: return preload("res://resources/effect_types/example_effect_type.tres")

# Ranging from -20% to +20%
func _get_new_percent() -> float: return randf_range(0.8, 1.2)

func _get_target_type() -> Module.TARGET:
	
	return Module.TARGET.ATTACKER if randf() > 0.5 else Module.TARGET.ATTACKEE
