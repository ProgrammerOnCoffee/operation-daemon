extends Modifier
## A test modifier that returns random values.

func _get_effect_type() -> Effect: return Effect.all_effects["timebomb_effect.gd"].new()

# Ranging from -60% to 60%, w/o anything below an abs value of 10%
func _get_new_percent() -> float: return 1 + ([-1,1].pick_random() * randf_range(0.1, 0.6))
