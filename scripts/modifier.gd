@abstract
class_name Modifier
extends Resource
## A modifier for an effect that changes the base value by a percentage.

## The list of all modifiers that can be given to enemies. Each key is an modifier's
## file name, and each value is that modifier's script loaded with [method @GDScript.load].
static var all_modifiers: Dictionary[String, GDScript]


static func _static_init() -> void:
	# Load all modifiers dynamically
	const PATH = "res://scripts/modifiers/"
	for file in DirAccess.get_files_at(PATH):
		if OS.has_feature("editor"):
			if not file.ends_with(".gd"):
				continue
		else:
			if not file.ends_with(".gd.remap"):
				continue
			file = file.substr(0, file.length() - ".remap".length())
		all_modifiers[file] = load(PATH.path_join(file))


# NOTE: these are all abstract functions and not variables
# so they can all be set by a subclass in code. The variables
# let you get the single-value ones like normal variables,
# but none can be set.

## The type of the effect. Used to apply effects.
var effect_type: Effect: get = _get_effect_type
@abstract func _get_effect_type() -> Effect
func compare_effect(to: Effect):
	return effect_type.effect_name == to.effect_name and effect_type.description == to.description

## The percentage change to apply to the effect's base, as a float. 0.9 = -10%.
var percent: float
@abstract func _get_new_percent() -> float

## Whether this modifier is applied to the attacker or attackee. 
## Basically, whether it's positive or negative to have applied to yourself.
var target_type: Module.TARGET
@abstract func _get_new_target_type() -> Module.TARGET

func _init() -> void:
	percent = _get_new_percent()
	target_type = _get_new_target_type()
