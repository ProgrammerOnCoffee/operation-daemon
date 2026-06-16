extends Effect

func _get_effect_name() -> String: return "Overcharge"
func _get_description() -> String: return "Increases damage dealt by %s%%, but damages the attacker by %s%% of the extra damage they deal." % [String.num(base * 100), String.num(base * 100)]

func _get_effect_color() -> Color: return Color.WHITE

func _get_base() -> float: return 0.3

func _get_effect_type() -> String: return "Damage"

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER

func _get_apply_type() -> ApplyType: return ApplyType.BEFORE_ATTACK

func apply_effect(target: Entity) -> bool:
	@warning_ignore_start("narrowing_conversion")
	var extra := target.damage_dealing * modified_base
	target.damage_dealing += extra
	target.health -= extra * modified_base
	return false
