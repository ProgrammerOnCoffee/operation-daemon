extends Node
## Holds all the static information regarding the player.

signal health_changed
signal modules_changed
signal daemons_changed

# I don't think we'll be changing this, but I'm gonna leave it un-uppercased
# just in case.
const max_health:int = 100

# The player's current health.
var health:int = 30:
	set(to):
		health = clamp(to, 0, max_health)
		health_changed.emit()

# The player's current modules.
var modules:Array[Module]:
	set(to): # NOTE: To trigger this use modules += [items] instead of .append()
		modules = to
		modules_changed.emit()

# The player's currently applied permanent daemons. (The ones chosen at the
# beginning of a run, or gotten from the random daemon event.)
var permanent_daemons:Array[Daemon]:
	set(to): # NOTE: To trigger this use permanent_daemons += [items] instead of .append()
		permanent_daemons = to
		
		# Make sure to put any that can be researched in the queue for that.
		# Should be just any event daemons.
		for daemon in permanent_daemons:
			Global.research(daemon, 0)
		
		daemons_changed.emit()

# The player's currently applied temporary daemons.
var daemons:Array[Daemon]:
	set(to): # NOTE: To trigger this use daemons += [items] instead of .append()
		daemons = to
		
		# Make sure to put any that can be researched in the queue for that.
		for daemon in daemons:
			Global.research(daemon, 0)
		
		daemons_changed.emit()

# Shorthand for all applicable daemons.
func all_daemons() -> Array[Daemon]: return permanent_daemons + daemons
