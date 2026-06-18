class_name ModuleEntry extends PanelContainer
## Displays a Module.

@onready var icon  := $HBoxContainer/Icon
@onready var title := $HBoxContainer/Title

@onready var buttons:Dictionary[Module.SLOT, Button] = {
	Module.SLOT.NONE:    $HBoxContainer/HBoxContainer/UN,
	Module.SLOT.ATTACK:  $HBoxContainer/HBoxContainer/AT,
	Module.SLOT.SPECIAL: $HBoxContainer/HBoxContainer/SP
}

var module:Module

func _ready() -> void:
	# Connect the buttons to the move requests.
	for slot in buttons:
		buttons[slot].pressed.connect(func(): 
			
			module.slot = slot
			PlayerData.modules_changed.emit()
			
			)

func _display(new_module:Module = module):
	module = new_module
	
	# Update the title.
	title.text = module.name
	
	# Update the icon pointcount and color.
	if module.effects:
		icon.points = module.effects[0].icon_point_count
		icon.modulate = module.effects[0].effect_color
	else:
		icon.points = 1
		icon.modulate = Color.WHITE
	
	# Make the button for where this already is disabled.
	for slot in buttons:
		buttons[slot].disabled = slot == module.slot 
