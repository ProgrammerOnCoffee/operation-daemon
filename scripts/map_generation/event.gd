class_name Event extends Resource
## A data-representation of the nodes on the world map.

enum TYPE {NONE, COMBAT, REST, ANALYSIS, DAEMON, BOSS}
# The type of event this is.
var type := TYPE.NONE

# The scenes for each type of room.
func get_new_scene() -> Node: 
	if SCENES.has(type): if SCENES[type] is PackedScene:
		return SCENES[type].instantiate()
	return null
const SCENES:Dictionary[TYPE, PackedScene] = {
	TYPE.COMBAT:   preload("res://scenes/event_scenes/combat_scene.tscn"),
	TYPE.REST:     preload("res://scenes/event_scenes/rest_scene.tscn"),
	TYPE.ANALYSIS: preload("res://scenes/event_scenes/analysis_scene.tscn"),
	TYPE.DAEMON:   preload("res://scenes/event_scenes/daemon_scene.tscn")
}

# The position of the event both on the map and on the grid.
var position:Vector2
var row:int
var column:int

# The next options for events after this one.
var next_options:Array[Event]

func _to_string() -> String: return "(%s/%s/%s)" % [row, column, type] #"CRADB"[type]
