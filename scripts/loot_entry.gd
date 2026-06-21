class_name LootEntry extends PanelContainer
## Displays a Module that can be taken as loot.

@onready var mod_icon  := $VBoxContainer/Button/HBoxContainer/Icon
@onready var title := $VBoxContainer/Button/HBoxContainer/Title

@onready var take_button

@onready var effect_box := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer
const EFFECT_TIP_SCENE := preload("res://scenes/effect_tooltip.tscn")

var module:Module

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
	
	# Make all the effect tips.
	for child in effect_box.get_children(): child.queue_free()
	
	for effect in module.effects:
		var new := EFFECT_TIP_SCENE.instantiate() as EffectTooltip
		
		effect_box.add_child(new)
		
		new.title_text_size = 18
		new.description_text_size = 15
		
		new._display(effect)


func _on_toggled(toggled_on: bool) -> void:
	$VBoxContainer/PanelContainer.visible = toggled_on


func _on_take_pressed() -> void:
	# Take the module. TAKE IT.
	
	# Make sure it's unequipped
	module.slot = Module.SLOT.NONE
	
	# Add it to the list of the player's modules.
	PlayerData.modules += [module] # Using += to trigger the signal.
	
	# Free this entry.
	queue_free()
	
