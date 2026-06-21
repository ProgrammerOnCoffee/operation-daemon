extends Effect

func _get_effect_name() -> String: return "Siphon"
func _get_description() -> String: return "Heals the attacker by %s%% of the damage they deal." % String.num(base * 100)

func _get_effect_color() -> Color: return Color(1.0, 0.991, 0.44, 1.0)
func _get_icon_point_count() -> int: return 8

func _get_base() -> float: return 0.2

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.AFTER_ATTACK

func apply_effect(target: Entity) -> bool:
	target.health += int(target.damage_dealing * base)
	return true
