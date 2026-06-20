extends Effect

func _get_effect_name() -> String: return "Strength"
func _get_description() -> String: return "Increase all damage dealt by " + Global.percent_as_string(base) + "."

func _get_effect_color() -> Color: return Color(0.81, 0.073, 0.343, 1.0)
func _get_icon_point_count() -> int: return 5

func _get_base() -> float: return 1.05

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.BEFORE_ATTACK

func apply_effect(target: Entity) -> bool:
	
	@warning_ignore("narrowing_conversion")
	target.damage_dealing *= base
	
	return true # Good god please don't let these stack every turn.
