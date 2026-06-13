class_name ExampleEffect extends Effect
# These probably don't even need class_names.
# An example healing effect.

## Name & Description for tooltips.
func _get_effect_name() -> String: return "Healing"
func _get_description() -> String: return "Heals the attacker by %s" % base 

## Heals 10.0 w/o any modifiers
func _get_base() -> float: return 10.0

## Will be effected by modifiers with the modification type "Heal"
func _get_modification_type() -> String: return "Heal"

## Targets the attacker
func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKER

## Actually do that healing.
func apply_effect(target:Node) -> bool:
	target.health += 10 # Or something like this - there aren't entities yet.
	return true ## Free immediately - no DoT
