extends Node
## Manages some global things, like the Daemon research.

## -- MUSIC -- ##
@warning_ignore("unused_signal")
signal request_track_transition(to:String)

## -- PROGRESSION -- ##

signal act_changed
signal act_completed
signal run_ended

var act := 1:
	set(to):
		act = to
		act_changed.emit()

## -- DAEMON RESEARCH -- ##

signal daemon_discovered(daemon:Daemon)

# The number of daemons that have ever existed, for their IDs.
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
	
	# Not the first time, add to the value.
	daemon_research[daemon] += amount
	return true

## Research all the currently-being-researched daemons by some amount.
## This should happen at the end of each Act, followed by attempt_discovery.
func research_all(amount:float = 0.10) -> void:
	
	# Unlike research(), these are all already valid, so no checking needed.
	for daemon in daemon_research:
		daemon_research[daemon] += amount

## Attempt to discover all daemons currently being researched.
func attempt_discovery() -> void:
	
	for daemon in daemon_research:
		# If the chance is passed, this daemon gets successfully researched.
		if randf() <= daemon_research[daemon]:
			
			daemons_discovered.append(daemon)
			daemon_research.erase(daemon)
			
			# Push out some kind of toast via this??
			daemon_discovered.emit(daemon)

## Returns a random newly-made daemon. Good for if we ever want modifiers to be weighted.
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
