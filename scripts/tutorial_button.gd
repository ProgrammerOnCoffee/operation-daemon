class_name TutorialButton extends Button

## Whether or not these buttons' panels are open. Persistent past queue-freeing.
static var states:Dictionary[NodePath, bool]
@onready var path := get_path()

## The control holding the actual information to show.
@export var info_panel:Control

## Another button that closes the panel, in case this one gets covered.
@export var close_button:BaseButton

func _ready() -> void:
	if not states.has(path):
		states[path] = true
	
	button_pressed = states[path]
	
	info_panel.visible = button_pressed
	
	close_button.pressed.connect(set_pressed.bind(false))

func _toggled(toggled_on: bool) -> void:
	if toggled_on: TransitionManager.transition(null, info_panel)
	else:          TransitionManager.transition(info_panel, null)
	
	states[path] = toggled_on
