extends Effect

func _get_effect_name() -> String: return "Poison"
func _get_description() -> String: return "Does damage every turn, starting at " + str(base) + " and decreasing by 1 per turn." 

func _get_effect_color() -> Color: return Color(0.213, 0.79, 0.261, 1.0)
func _get_icon_point_count() -> int: return 1

func _get_base() -> float: return 2

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKEE
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.AFTER_ATTACK

func apply_effect(target: Entity) -> bool:
	
	target.take_damage(Global.float_as_chance_int(base))
	
	base -= 1.
	
	return base <= 0
