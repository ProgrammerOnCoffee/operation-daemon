class_name Event extends Resource
## A data-representation of the nodes on the world map.

enum TYPE {NONE, COMBAT, REST, ANALYSIS, DISEASE, BOSS}
# The type of event this is.
var type := TYPE.NONE

# The position of the event both on the map and on the grid.
var position:Vector2
var row:int
var column:int

# The next options for events after this one.
var next_options:Array[Event]

func _to_string() -> String: return str(next_options.size()) #"CRADB"[type]
