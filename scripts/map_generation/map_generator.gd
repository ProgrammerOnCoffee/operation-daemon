class_name MapGenerator extends Control
## Manages the generation of a map.

const CONFIGS:Array[MapConfig] = [
	preload("res://resources/map_configs/Act1.tres"),
	preload("res://resources/map_configs/Act2.tres"),
	preload("res://resources/map_configs/Act3.tres"),
	]

## The spacing between nodes on the map.
const SPACING := Vector2(80, 80)
## The range-randomness applied to the nodes' position on the map.
const VARIATION := Vector2(0,0)

@export var config:MapConfig

## The map as a two-dimensional array of nodes.
var map_data:Array[Array]

## Generate a map.
func generate_map() -> Array[Array]:
	
	config = CONFIGS[Global.act]
	
	if not config:
		push_warning("Tried to generate a map with no config. No.")
		return []
	
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	
	# Make the room connections.
	for j in starting_points:
		var current_j := j
		for i in config.floor_count - 1:
			current_j = _setup_connection(i, current_j)
	
	_setup_boss_event()
	_setup_event_types()
	
	return []

## Generate the initial grid, before any connections are made.
func _generate_initial_grid() -> Array[Array]:
	var result:Array[Array] = []
	
	for i in config.floor_count:
		var floor_events:Array[Event] = []
		
		for j in config.map_width:
			var new_event := Event.new()
			var offset := (Vector2(randf(), randf()) - Vector2(.5,.5)) * VARIATION * 2
			
			new_event.position = Vector2(j * SPACING.x, i * -SPACING.y) + offset
			new_event.row    = i
			new_event.column = j
			
			new_event.next_options = []
			
			## Extra spacing and no randomness for BIG BOSS room height.
			if i == config.floor_count - 1:
				new_event.position.y = (i + 1) * -SPACING.y
			
			# Push out the events into an array for the floor
			floor_events.append(new_event)
		# Push the floor array into the larger one for the grid.
		result.append(floor_events)
	
	return result

## Get the starting indices for the paths.
func _get_random_starting_points() -> Array[int]:
	## Needs to have at least 2 unique ones.
	
	var points:Array[int]
	
	## Bag pick the first two so they're always different.
	var bag := range(config.map_width)
	for i in 2: points.append(bag.pop_at(randi_range(0, len(bag) - 1)))
	
	## For the rest, just pick random numbers man.
	for i in config.paths - 2:
		points.append(randi_range(0, config.map_width - 1))
	
	return points

## Connect a room to one above it.
func _setup_connection(row:int, column:int) -> int:
	var next_event:Event
	var current_room := map_data[row][column] as Event
	
	while not next_event or _would_cross_existing_path(row, column, next_event):
		
		# Next room is a floor up, in a column within 1 step of this room's column.
		var random_column := clampi(randi_range(column - 1, column + 1), 0, config.map_width - 1)
		next_event = map_data[row + 1][random_column]
	
	current_room.next_options.append(next_event)
	
	return next_event.column

## Returns if an attempted connection would cause a cross of path lines (X). No bueno.
func _would_cross_existing_path(i:int, j:int, event:Event) -> bool:
	
	var left_neighbor:Event
	var right_neighbor:Event
	
	if j > 0:                    left_neighbor  = map_data[i][j - 1]
	if j < config.map_width - 1: right_neighbor = map_data[i][j + 1]
	
	# IF there's a neighbor to the right and the attempted connection is that way, there can be a X
	if right_neighbor and event.column > j:
		# Check for crosses in the existing connections.
		for next_event:Event in right_neighbor.next_options:
			if next_event.column < event.column: return true
	
	# IF there's a neighbor to the left and the attempted connection is that way, there can be a X
	if left_neighbor and event.column < j:
		# Check for crosses in the existing connections.
		for next_event:Event in left_neighbor.next_options:
			if next_event.column > event.column: return true
	
	return false

## Make the top floor of the act have a boss room in the middle, 
## and connect all preceding rooms to it.
func _setup_boss_event() -> void:
	
	var middle := floori(config.map_width / 2.)
	var boss_event := map_data[config.floor_count - 1][middle] as Event
	
	# Connect all the rooms below to the boss.
	for j in config.map_width:
		var current_event := map_data[config.floor_count - 2][j] as Event
		
		# This event has connections, so they should be just the boos roos.
		if current_event.next_options:
			current_event.next_options = [boss_event]
	
	boss_event.type = Event.TYPE.BOSS

## Set the types up for all the rooms.
func _setup_event_types() -> void:
	
	# Make a bag to get weighted types from.
	var type_bag:Array[Event.TYPE]
	for type in Event.TYPE.size():
		if not config.event_weights.has(type): continue
		for i in config.event_weights[type]:
			type_bag.append(type)
	
	# Trace the paths up and fill in event types.
	var to_be_assigned:Array[Event]
	for j in config.map_width:
		var this_event := map_data[0][j] as Event
		if this_event.next_options and not to_be_assigned.has(this_event):
			to_be_assigned.append(this_event)
	
	# Apply all the random types
	while to_be_assigned:
		var this_event := to_be_assigned.pop_front() as Event
		
		if this_event.type != Event.TYPE.NONE: continue
		
		this_event.type = type_bag.pick_random()
		
		# Add the connections from this room up to the queue.
		# At the end, so they won't be done until they can't be re-added.
		for event in this_event.next_options:
			if not to_be_assigned.has(event):
				to_be_assigned.append(event)
	
	# Apply all the type overrides.
	for override in config.event_overrides:
		var row := wrapi(override, 0, config.floor_count)
		var type := config.event_overrides[override] as Event.TYPE
		
		for column in config.map_width:
			var this_event := map_data[row][column] as Event
			
			# This is a valid event to set (it was already randomized) - do that.
			if this_event.type != Event.TYPE.NONE:
				this_event.type = type

## Get all the events in the map that actually do things.
func get_active_events() -> Array[Event]:
	
	var events:Array[Event]
	
	for i in map_data.size():
		for j in map_data[i].size():
			var this_event := map_data[i][j] as Event
			if this_event.type != Event.TYPE.NONE:
				events.append(this_event)
	
	return events
