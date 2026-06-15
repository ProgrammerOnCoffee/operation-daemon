extends Node
## Manages some global things, like the Daemon research.

## -- DAEMON RESEARCH -- ##

signal daemon_discovered(daemon:Daemon)

# The number of daemons that have ever existed, for their IDs.
var daemon_count:int = 0

## All the daemons discovered and available for perm-buffs.
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
