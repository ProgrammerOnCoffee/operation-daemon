class_name Module
extends Resource
## A carrier of Effects onto their targets. Literally just a bundle of Effects.

enum TARGET {
	ATTACKER, ## Apply the effect to the attacker upon their attack.
	ATTACKEE ## Apply the effect to the attackee upon an attack.
}

enum SLOT {
	NONE,   ## This module isn't in a slot - it won't be applied during combat.
	ATTACK, ## This module is in a ATTACK  slot - apply it w/ ATTACKs
	SPECIAL ## This module is in a SPECIAl slot - apply it w/ SPECIALS.
}

## This [Module]'s unique ID.
var id: int
## The unique name of this [Module].
var name: String
## The array of  [Effect]s contained in this [Module].
var effects: Array[Effect]
## Which type of slot this module is in.
var slot := SLOT.NONE

func _init(set_effects: Array[Effect], set_slot:SLOT = SLOT.NONE) -> void:
	effects = set_effects
	Global.module_count += 1
	id = Global.module_count
	name = "D%d" % id
	slot = set_slot
