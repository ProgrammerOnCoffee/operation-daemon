@abstract
class_name Effect
extends Resource
## An effect that's applied to a target every turn cycle.

## When this [Effect] should be applied.
enum ApplyType {
	BEFORE_ATTACK, ## Apply this effect before attacking.
	AFTER_ATTACK, ## Apply this effect after attacking.
	BEFORE_DAMAGE, ## Apply this effect before taking damage.
	AFTER_DAMAGE, ## Apply this effect after taking damage.
}

## The list of all effects that can be given to enemies. Each key is an effect's
## file name, and each value is that effect's script loaded with [method @GDScript.load].
static var all_effects: Dictionary[String, GDScript]


static func _static_init() -> void:
	# Load all effects dynamically
	const PATH = "res://scripts/effects/"
	for file in DirAccess.get_files_at(PATH):
		if OS.has_feature("editor"):
			if not file.ends_with(".gd"):
				continue
		else:
			if not file.ends_with(".gd.remap"):
				continue
			file = file.substr(0, file.length() - ".remap".length())
		all_effects[file] = load(PATH.path_join(file))

# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

## The name of the effect. 
var effect_name: String: get = _get_effect_name
@abstract func _get_effect_name() -> String

## The description of the effect.
var description: String: get = _get_description
@abstract func _get_description() -> String

## The color of the effect - applied as a modulate to enemies. 
var effect_color: Color: get = _get_effect_color
@abstract func _get_effect_color() -> Color

## Whether this effect should be applied to the attacker or attackee
var target_type: Module.TARGET: get = _get_target_type
@abstract func _get_target_type() -> Module.TARGET

## When this effect should be applied.
var apply_type: ApplyType: get = _get_apply_type
@abstract func _get_apply_type() -> ApplyType

## The base value of the effect. Can be changed via Modifiers.
var base: float: get = _get_base
@abstract func _get_base() -> float 

## Apply this effect to a target. Ran by that target.
## Returns a bool of whether it should be freed after it's run.
@abstract func apply_effect(target: Entity) -> bool

func _to_string() -> String: return effect_name + ": " + str(base)
