class_name DaemonOverview extends VBoxContainer
## Takes in a daemon, and displays all the relevant information regarding it.

# The colors for positive and negative traits.
const POSITIVE_COLOR := Color(0.32, 1.0, 0.411, 1.0)
const NEGATIVE_COLOR := Color(1.0, 0.32, 0.32, 1.0)

var daemon :Daemon: set = _set_daemon

@onready var vboxes:Dictionary[Module.TARGET, VBoxContainer] = {
	Module.TARGET.ATTACKER: $ScrollContainer/VBoxContainer/Self,
	Module.TARGET.ATTACKEE: $ScrollContainer/VBoxContainer/Target
}
@onready var title := $Title

func _ready() -> void:
	var test_daemon := Daemon.new()
	
	for i in 1000:
		test_daemon.modifiers += [TestModifier.new()]
	
	daemon = test_daemon

# Update the overview when the daemon changes.
func _set_daemon(to:Daemon):
	
	daemon = to
	
	if daemon:
		
		# Update the title.
		
		title.text = "D%s" % lead(daemon.id, 4)
		
		# Clear the VBoxes of any previous information.
		for vbox in vboxes.values(): for child in vbox.get_children(): child.queue_free()
		
		# Add each modifier to its respective list.
		for modifier in daemon.modifiers: push_text(modifier)
		
	else:
		title.text = "None"
		
		# Clear the VBoxes of any previous information.
		for vbox in vboxes.values(): for child in vbox.get_children(): child.queue_free()

func push_text(modifier:Modifier) -> Label:
	
	var text = "%s %s" % [percent_as_string(modifier.percent), modifier.effect_type.effect_name]
	
	var new := Label.new()
	
	new.text = text
	
	new.add_theme_color_override("font_color", POSITIVE_COLOR if modifier.percent >= 1. else NEGATIVE_COLOR)
	
	vboxes[modifier.target_type].add_child(new)
	
	new.mouse_filter = Control.MOUSE_FILTER_PASS
	new.tooltip_text = modifier.effect_type.effect_name + "\n--\n" + modifier.effect_type.description
	
	return new

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
