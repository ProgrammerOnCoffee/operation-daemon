class_name MapConfig extends Resource
## The configuration of a map, to be plugged into a MapGenerator.
## Allows for different configurations per act.

## How many rooms the player has to cross through in this act. Y dimension.
@export var floor_count := 13
## How many options there'll be across at the start. X dimension.
@export_range(1, 13, 2) var map_width   := 7
## How many paths there will be through the map. != starting_points.
@export_range(2, 13, 1) var paths := 4

## Set a certain layer of the map to all one type. 
## The value wraps, so you can say negative numbers to go from the top down.
@export var event_overrides:Dictionary[int, Event.TYPE] = {
	0: Event.TYPE.COMBAT, ## First layer's combat.
	-2: Event.TYPE.COMBAT, ## -1 is the boss layer - layer before that is all rests.
}

@export var event_weights:Dictionary[Event.TYPE, int] = {
	Event.TYPE.COMBAT: 8,
	Event.TYPE.REST: 3,
	Event.TYPE.ANALYSIS: 1,
	Event.TYPE.DISEASE: 1
}
