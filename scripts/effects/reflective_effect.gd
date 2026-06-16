extends Effect

func _get_effect_name() -> String: return "Reflective"
func _get_description() -> String: return "When attacked, damages the attacker by %s%% of the damage they deal." % String.num(base * 100) 

func _get_effect_color() -> Color: return Color.WHITE

func _get_base() -> float: return 0.2

func _get_modification_type() -> String: return "Damage"

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKEE

func _get_apply_type() -> ApplyType: return ApplyType.AFTER_DAMAGE

func apply_effect(target: Entity) -> bool:
	@warning_ignore("narrowing_conversion")
	target.health -= target.damage_dealing * modified_base
	return false
