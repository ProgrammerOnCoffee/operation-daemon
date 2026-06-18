@tool
class_name DaemonOverview extends VBoxContainer
## Takes in a daemon, and displays all the relevant information regarding it.

@export var show_title := true:
	set(to):
		if title:
			title.visible = to
		show_title = to

var daemon :Daemon = null: set = _set_daemon

@onready var vbox := $ScrollContainer/VBoxContainer
@onready var title := $Title

func _ready() -> void: title.visible = show_title

# Update the overview when the daemon changes.
func _set_daemon(to:Daemon):
	
	daemon = to
	
	if daemon:
		
		# Update the title.
		
		title.visible = show_title
		title.text = "D%s" % Global.lead(daemon.id, 4)
		
		# Clear the VBox of any previous information.
		for child in vbox.get_children(): child.queue_free()
		
		# Add each modifier to its respective list.
		for modifier in daemon.modifiers: push_text(modifier)
		
	else:
		title.text = "None"
		
		# Clear the VBox of any previous information.
		for child in vbox.get_children(): child.queue_free()

func push_text(modifier:Modifier) -> Label:
	return ModifierLabel.new(modifier, vbox)
