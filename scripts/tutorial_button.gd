class_name TutorialButton extends Button

## Allows for single-use triggering of tutorial panels. Good for opening a panel
## the first time something happens.
static var excluded_triggers:Array[StringName]
func trigger(id:StringName, _node_path:NodePath):
	
	# I only ended up using this in *one place*, and that place
	# could use a delay.
	await get_tree().create_timer(2.0).timeout
	
	if excluded_triggers.has(id): return
	button_pressed = true
	excluded_triggers.append(id)

## Whether or not these buttons' panels are open. Persistent past queue-freeing.
static var states:Dictionary[NodePath, bool]
@onready var path := get_path()

## The control holding the actual information to show.
@export var info_panel:Control

## Another button that closes the panel, in case this one gets covered.
@export var close_button:BaseButton

func _ready() -> void:
	if not states.has(path):
		states[path] = info_panel.visible
	
	button_pressed = states[path]
	
	info_panel.visible = button_pressed
	
	if close_button:
		close_button.pressed.connect(set_pressed.bind(false))

func _toggled(toggled_on: bool) -> void:
	
	#print("TRANS ", info_panel)
	if toggled_on: TransitionManager.transition(null, info_panel)
	else:          TransitionManager.transition(info_panel, null)
	
	states[path] = toggled_on
