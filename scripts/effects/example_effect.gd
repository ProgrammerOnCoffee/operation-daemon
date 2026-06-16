extends Effect
# An example healing effect.

## Name & Description for tooltips.
func _get_effect_name() -> String: return "Healing"
func _get_description() -> String: return "Heals the attacker by %d HP." % base

func _get_effect_color() -> Color: return Color.BLUE

## Heals 10.0 w/o any modifiers
func _get_base() -> float: return 10.0

## Will be effected by modifiers with the modification type "Heal"
func _get_effect_type() -> String: return "Heal"

## Targets the attacker
func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER

## Apply this effect after attacking.
func _get_apply_type() -> ApplyType: return ApplyType.AFTER_ATTACK

## Actually do that healing.
func apply_effect(target: Entity) -> bool:
	target.health += int(modified_base) # Or something like this
	return true ## Free immediately - no DoT
