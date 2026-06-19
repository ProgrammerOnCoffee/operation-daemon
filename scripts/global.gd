extends Node
## Manages some global things, like the Daemon research.

## -- MISC -- ##
@warning_ignore("unused_signal")
signal request_track_transition(to:String)
@warning_ignore("unused_signal")
signal push_toast(text:String) # Ask the toast manager to make some toast.

## -- CONFIGURATION -- ##
# Every two elements are the min and max number of x that each enemy will have.
## The min and max number of modules each enemy will have in each act.
const ACT_MODULES = [1, 1, 2, 2, 3, 3]
## The min and max number of effects each module will have in each act.
const ACT_EFFECTS = [1, 1, 1, 2, 2, 2]
## The min and max number of daemons each enemy will have in each act.
const ACT_DAEMONS = [2, 2, 4, 5, 6, 7]
## The min and max number of positive modifiers each daemon will have in each act.
const ACT_POS_MODIFIERS = [1, 2, 2, 3, 3, 4]
## The min and max number of negative modifiers each daemon will have in each act.
const ACT_NEG_MODIFIERS = [2, 3, 3, 4, 4, 4]

## -- PROGRESSION -- ##

signal act_changed
signal act_completed
signal run_ended

var act := 1:
	set(to):
		act = to
		act_changed.emit()

## The number of modules that have ever existed. Used to give each module a unique ID.
var module_count:int = 0

## -- DAEMON RESEARCH -- ##

signal daemon_discovered(daemon:Daemon)

## The number of daemons that have ever existed. Used to give each module a unique ID.
var daemon_count:int = 0

## All the daemons discovered and available for use as permanent buffs in a run.
var daemons_discovered:Array[Daemon]
## All the daemons being researched. Cleared on death.
var daemon_research:Dictionary[Daemon, float]

## Research a daemon by a certain amount. 5% by default.
## This should happen whenever the player takes damage from a daemon.
func research(daemon:Daemon, amount:float = 0.05) -> bool:
	
	# No researching already discovered daemons.
	if daemons_discovered.has(daemon): return false
	
	# First time being researched - add to the dict.
	if not daemon_research.has(daemon):
		daemon_research[daemon] = 0
	
	# Add to the research value.
	daemon_research[daemon] += amount
	
	return true

func research_group(daemons:Array[Daemon], amount := 0.05) -> void: for daemon in daemons: research(daemon, amount)

## Research all the currently-being-researched daemons by some amount.
## This should happen at the end of each Act, followed by attempt_discovery.
func research_all(amount:float = 0.10) -> void:
	
	# Unlike research(), these are all already valid, so no checking needed.
	for daemon in daemon_research:
		daemon_research[daemon] += amount

## Attempt to discover all daemons currently being researched.
func attempt_discovery() -> void:
	
	print("ATTEMPT DISCOVERY -> ")
	
	for daemon in daemon_research:
		# If the chance is passed, this daemon gets successfully researched.
		if randf() <= daemon_research[daemon]:
			
			daemons_discovered.append(daemon)
			daemon_research.erase(daemon)
			
			# Push out some kind of toast via this??
			daemon_discovered.emit(daemon)

## Returns a random newly-made daemon.
func get_random_daemon(modifier_count := 4) -> Daemon:
	
	var modifiers:Array[Modifier]
	
	for i in modifier_count:
		modifiers.append(modifier_sources.pick_random().new())
	
	return Daemon.new(modifiers)

## Create an array of all the modifiers in existence
@onready var modifier_sources:Array[Resource] = _get_modifier_sources()
func _get_modifier_sources() -> Array[Resource]:
	
	var results:Array[Resource]
	
	var path := "res://scripts/modifiers/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.right(3) == ".gd":
					results.append(load(path + file_name))
				
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	return results

## General Functions

# Add leading zeros to an int. 13 with 4 zeros becomes "0013"
func lead(value:int, zeros:int) -> String:
	
	var response := ""
	var string = str(value)
	
	for i in zeros - len(string):
		response += "0"
	response += string
	
	return response

func percent_as_string(percent:float) -> String:
	var response:String
	
	if percent >= 1.0:
		response += "+"
		percent -= 1.
	else:
		response += "-"
		percent = 1. - percent
	
	response += str(round(percent * 10000) / 100) + "%"
	
	return response

# Returns the float as if it was a chance to add 1 to an int.
# Every 1 is +1, every 0.3 is a 30% chance for +1, etc.
func float_as_chance_int(value:float) -> int:
	var response := floori(value)
	var percent  := abs(value - response) as float
	
	if randf() <= percent:
		response += sign(value) # Match the sign, so if the input is -0.3, it's a 30% chance for -1.
	
	return response
