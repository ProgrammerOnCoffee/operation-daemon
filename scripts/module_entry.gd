class_name ModuleEntry extends PanelContainer
## Displays a Module.

@onready var mod_icon  := $VBoxContainer/Button/HBoxContainer/Icon
@onready var title := $VBoxContainer/Button/HBoxContainer/Title

@onready var effect_box := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer
const EFFECT_TIP_SCENE := preload("res://scenes/effect_tooltip.tscn")

@onready var buttons:Dictionary[Module.SLOT, Button] = {
	Module.SLOT.NONE:    $VBoxContainer/Button/HBoxContainer/UN,
	Module.SLOT.ATTACK:  $VBoxContainer/Button/HBoxContainer/HBoxContainer/AT,
	Module.SLOT.SPECIAL: $VBoxContainer/Button/HBoxContainer/HBoxContainer/SP
}

var module:Module

func _ready() -> void:
	# Connect the buttons to the move requests.
	for slot in buttons:
		buttons[slot].pressed.connect(func(): 
			
			module.slot = slot
			PlayerData.modules_changed.emit()
			
			)
	
	$VBoxContainer/Button.button_pressed = false

func _display(new_module:Module = module):
	module = new_module
	
	# Update the title.
	title.text = module.name
	
	# Update the icon pointcount and color.
	if module.effects:
		mod_icon.points = module.effects[0].icon_point_count
		mod_icon.modulate = module.effects[0].effect_color
	else:
		mod_icon.points = 1
		mod_icon.modulate = Color.WHITE
	
	# Make the button for where this already is disabled.
	for slot in buttons:
		buttons[slot].disabled = slot == module.slot 
	
	# Make all the effect tips.
	for child in effect_box.get_children(): child.queue_free()
	
	for effect in module.effects:
		var new := EFFECT_TIP_SCENE.instantiate() as EffectTooltip
		
		effect_box.add_child(new)
		
		new.title_text_size = 18
		new.description_text_size = 15
		
		new._display(effect)
	
	match module.slot:
		Module.SLOT.NONE:
			$VBoxContainer/Button/HBoxContainer/HBoxContainer.show()
			$VBoxContainer/Button/HBoxContainer/UN.hide()
		_:
			$VBoxContainer/Button/HBoxContainer/HBoxContainer.hide()
			$VBoxContainer/Button/HBoxContainer/UN.show()


func _on_toggled(toggled_on: bool) -> void:
	$VBoxContainer/PanelContainer.visible = toggled_on
