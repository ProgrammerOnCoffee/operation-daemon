class_name Daemon extends Resource
## A carrier of Modifiers onto modifiers. Literally just a bundle of Modifiers

## Have some global var that keeps track of 'num of daemons made', 
## and make the name just 'D0001', etc. Tick up the counter and set the name in init.
var name:String

var modifiers:Array[Modifier]:
	set(to):
		modifiers = compound_modifiers(to)

var id:int

func _init(set_modifiers:Array[Modifier] = []) -> void:
	modifiers = set_modifiers
	
	Global.daemon_count += 1
	id = Global.daemon_count

## Combine any modifiers whose only difference is percent.
func compound_modifiers(input:Array[Modifier]) -> Array[Modifier]:
	var compounded_modifiers:Array[Modifier]
	
	for modifier in input:
		var found := false
		
		for check_modifier in compounded_modifiers:
			if found: continue
			if modifier.compare_effect(check_modifier.effect_type) and check_modifier.target_type == modifier.target_type:
				check_modifier.percent *= modifier.percent
				found = true
		
		if not found:
			compounded_modifiers.append(modifier)
	
	return compounded_modifiers
