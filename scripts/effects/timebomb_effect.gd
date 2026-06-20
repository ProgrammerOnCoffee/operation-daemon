extends Effect

func _get_effect_name() -> String: return "Timebomb"
func _get_description() -> String: return "Every attack applies a bomb, which has a 50% chance of exploding each turn. Every turn it doesn't explode, its damage goes up by " + str(base) + ". Starts at 0 dmg." 

func _get_effect_color() -> Color: return Color(0.95, 0.427, 0.427, 1.0)
func _get_icon_point_count() -> int: return 4

func _get_base() -> float: return 1

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKEE
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.BEFORE_ATTACK

var damage := 0
func apply_effect(target: Entity) -> bool:
	
	if randf() < 0.6:
		# Yes Rico, kaboom.
		
		target.take_damage(damage)
		
		return true # No more bomb ._.
	
	damage += Global.float_as_chance_int(base)
	return false
