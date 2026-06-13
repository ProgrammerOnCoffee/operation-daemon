class_name Module extends Resource
## A carrier of Effects onto their targets. Literally just a bundle of Effects.

## Have some global var that keeps track of 'num of modifiers made', 
## and make the name just 'M0001', etc. Tick up the counter and set the name in init.
var name:String

var effects:Array[Effect]

func _init(set_effects:Array[Effect]) -> void:
	effects = set_effects

enum TARGET {
	ATTACKER, ## Apply the effect to the attacker upon their attack.
	ATTACKEE ## Apply the effect to the attackee upon an attack.
}
