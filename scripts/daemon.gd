class_name Daemon
extends Resource
## A carrier of modifiers onto modifiers. Literally just a bundle of Modifiers

## This [Daemon]'s unique ID.
var id: int
## This [Daemon]'s unique name.
var name: String
## This [Daemon]'s point count for icons.
var point_count:int
## The array of [Modifier]s contained in this [Daemon].
var modifiers: Array[Modifier]:
	set(to):
		modifiers = Daemon.compound_modifiers(to)


## Combine any modifiers whose only difference is percent.
static func compound_modifiers(input: Array[Modifier]) -> Array[Modifier]:
	var compounded_modifiers: Array[Modifier]
	
	for modifier in input:
		## Whether or not a matching modifier was found for this modifier.
		var found := false
		
		for check_modifier in compounded_modifiers:
			if modifier.compare_effect(check_modifier.effect_type):
				check_modifier.percent *= modifier.percent
				found = true
				break
		
		if not found:
			compounded_modifiers.append(modifier)
	
	return compounded_modifiers


func _init(set_modifiers: Array[Modifier] = []) -> void:
	modifiers = set_modifiers
	
	Global.daemon_count += 1
	id = Global.daemon_count
	name = "D%s" % Global.lead(id,4)
	
	point_count = randi_range(2, 8)
	if point_count == 2: point_count = 1
