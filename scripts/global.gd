extends Node
## Manages some global things, like the Daemon research.

## -- MISC -- ##
@warning_ignore("unused_signal")
signal request_track_transition(to:String)
@warning_ignore("unused_signal")
signal push_toast(text:String) # Ask the toast manager to make some toast.

## -- CONFIGURATION -- ##

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


func _ready() -> void:
	act_changed.connect(generate_enemy_pool)


#region Enemy pool

var ALL_ENTITIES: Dictionary[String, PackedScene] = {
	"angel": load("res://scenes/entities/angel.tscn"),
	"dino_slime": load("res://scenes/entities/dino_slime.tscn"),
	"m_slime": load("res://scenes/entities/m_slime.tscn"),
	"slime_spider_bot": load("res://scenes/entities/slime_spider_bot.tscn"),
}
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

## The pool of enemies that will be used throughout the current act.
var enemy_pool: Array[Enemy]


## Generates a new pool of enemies that will be used throughout the current act.
func generate_enemy_pool() -> void:
	## The set of available enemies in this act.
	var available_enemies = (
		[ALL_ENTITIES.slime_spider_bot, ALL_ENTITIES.m_slime] if act == 0
		else [ALL_ENTITIES.slime_spider_bot, ALL_ENTITIES.m_slime, ALL_ENTITIES.dino_slime] if act == 1
		else [ALL_ENTITIES.slime_spider_bot, ALL_ENTITIES.m_slime, ALL_ENTITIES.dino_slime, ALL_ENTITIES.angel]
	)
	## The number of enemies in this act's pool.
	var pool_size := randi_range(6, 8)
	enemy_pool.resize(pool_size)
	for i in pool_size:
		var enemy := available_enemies.pick_random().instantiate() as Enemy
		
		# Give enemy modules and daemons
		var act_min := 2 * Global.act
		var act_max := 2 * Global.act + 1
		for j in randi_range(Global.ACT_MODULES[act_min], Global.ACT_MODULES[act_max]):
			var effects: Array[Effect]
			for k in randi_range(Global.ACT_EFFECTS[act_min], Global.ACT_EFFECTS[act_max]):
				var effect := Effect.all_effects.values().pick_random().new() as Effect
				effects.append(effect)
			enemy.modules.append(Module.new(effects))
		
		for l in randi_range(Global.ACT_DAEMONS[act_min], Global.ACT_DAEMONS[act_max]):
			var modifiers: Array[Modifier]
			## The remaining number of positive modifiers to generate.
			var pos_mod_n := randi_range(Global.ACT_POS_MODIFIERS[act_min], Global.ACT_POS_MODIFIERS[act_max])
			## The remaining number of negative modifiers to generate.
			var neg_mod_n := randi_range(Global.ACT_NEG_MODIFIERS[act_min], Global.ACT_NEG_MODIFIERS[act_max])
			while pos_mod_n or neg_mod_n:
				var modifier := Modifier.all_modifiers.values().pick_random().new() as Modifier
				if pos_mod_n == 0:
					# Only add modifier if it's negative
					if not modifier._is_beneficial():
						modifiers.append(modifier)
						neg_mod_n -= 1
				elif neg_mod_n == 0:
					# Only add modifier if it's positive
					if modifier._is_beneficial():
						modifiers.append(modifier)
						pos_mod_n -= 1
				else:
					# Add modifier regardless of whether it's positive or negative
					modifiers.append(modifier)
					if modifier._is_beneficial():
						pos_mod_n -= 1
					else:
						neg_mod_n -= 1
			enemy.daemons.append(Daemon.new(modifiers))
		enemy_pool[i] = enemy


## Picks an enemy from the [member enemy_pool] and creates an [Entity3D] for it.
func pick_enemy() -> Entity3D:
	## The selected [Enemy].
	var enemy := enemy_pool.pick_random() as Enemy
	## The duplicated [Enemy] that will actually be loaded into the fight.
	var entity := enemy.duplicate() as Enemy
	entity.daemons = enemy.daemons
	var entity_3d := Entity3D.new()
	entity_3d.entity = entity
	return entity_3d


#endregion

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
		modifiers.append(Modifier.all_modifiers.values().pick_random().new())
	
	return Daemon.new(modifiers)

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
