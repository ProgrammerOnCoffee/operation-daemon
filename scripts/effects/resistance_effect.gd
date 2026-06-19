extends Effect

func _get_effect_name() -> String: return "Resistance"
func _get_description() -> String: return "Decrease all damage taken by " + Global.percent_as_string(base) + "."

func _get_effect_color() -> Color: return Color(0.31, 0.337, 0.86, 1.0)
func _get_icon_point_count() -> int: return 7

func _get_base() -> float: return 1.05

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.BEFORE_DAMAGE

func apply_effect(target: Entity) -> bool:
	
	@warning_ignore("narrowing_conversion")
	target.damage_receiving /= base
	
	return true # Good god please don't let these stack every turn.
