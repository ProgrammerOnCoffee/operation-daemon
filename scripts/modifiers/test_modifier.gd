extends Modifier
## A test modifier that returns random values.

func _get_effect_type() -> Effect: return Effect.all_effects["example_effect.gd"].new()

# Ranging from -20% to +20%
func _get_new_percent() -> float: return randf_range(0.9, 1.1)
