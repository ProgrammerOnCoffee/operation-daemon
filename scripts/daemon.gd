class_name Daemon extends Resource
## A carrier of Modifiers onto modifiers. Literally just a bundle of Modifiers

## Have some global var that keeps track of 'num of daemons made', 
## and make the name just 'D0001', etc. Tick up the counter and set the name in init.
var name:String

var modifiers:Array[Modifier]

var id:int

func _init(set_modifiers:Array[Modifier] = []) -> void:
	modifiers = set_modifiers
	
	Global.daemon_count += 1
	id = Global.daemon_count
