extends Effect

func _get_effect_name() -> String: return "Overcharge"
func _get_description() -> String: return "Increases damage dealt by %s%%, but damages the attacker by %s%% of the extra damage they deal." % [String.num(base * 100), String.num(base * 100)]

func _get_effect_color() -> Color: return Color(0.82, 0.479, 0.18, 1.0)
func _get_icon_point_count() -> int: return 3

func _get_base() -> float: return 0.3

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.BEFORE_ATTACK

func apply_effect(target: Entity) -> bool:
	var extra := floori(target.damage_dealing * base)
	
	target.damage_dealing += extra
	target.take_damage(floori(extra * base))
	
	return true
