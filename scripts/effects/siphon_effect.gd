extends Effect

func _get_effect_name() -> String: return "Siphon"
func _get_description() -> String: return "Heals the attacker by %s%% of the damage they deal." % String.num(base * 100)

func _get_effect_color() -> Color: return Color.WHITE

func _get_base() -> float: return 0.4

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER

func _get_apply_type() -> ApplyType: return ApplyType.AFTER_ATTACK

func apply_effect(target: Entity) -> bool:
	target.health += int(target.damage_dealing * base)
	return true
