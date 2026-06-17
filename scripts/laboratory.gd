extends ColorRect

@export var map:Control

@onready var tab_bar          := $HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer/TabBar
@onready var scroll_container := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer
var goal_scroll_position:float

var daemon_dictionary:Dictionary[String, Daemon] # Turn an ID back into a Daemon.

## Recombiner
@onready var recomb_reroll_options  := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/OptionButton
@onready var recomb_reroll_overview := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DaemonOverview
@onready var recomb_using_options   := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton
@onready var recomb_using_overview  := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/DaemonOverview
@onready var recomb_reroll_button   := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/Button
var recomb_reroll_selection:Daemon
var recomb_using_selection:Daemon

## Injector
@onready var injector_item_list    := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/ItemList
@onready var injector_overview     := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/DaemonOverview
@onready var injector_equip_button := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/Button
var injector_selection:Daemon

func _ready() -> void:
	
	tab_bar.tab_selected.connect(func(index:int): goal_scroll_position = index * 496)
	
	for i in 10:
		Global.daemons_discovered += [Global.get_random_daemon(7)]
	
	_update_discovered_list()

func _process(delta: float) -> void:
	scroll_container.scroll_horizontal = move_toward(scroll_container.scroll_horizontal, goal_scroll_position, 493 * (delta / 0.1)) # Move 493px in 0.1s

func _start_pressed() -> void: 
	# Reset the current act.
	Global.act = 0
	
	TransitionManager.transition_screen(self, map)

func _update_discovered_list() -> void:
	
	# Clear existing lists
	injector_item_list.clear()
	recomb_reroll_options.clear()
	recomb_using_options.clear()
	
	var i = 0
	for daemon in Global.daemons_discovered:
		var id := "D%s" % Global.lead(daemon.id, 4)
		
		daemon_dictionary[id] = daemon
		
		# Add each daemon to the lists.
		injector_item_list   .add_item(id)
		recomb_reroll_options.add_item(id)
		recomb_using_options.add_item(id)
		
		# Auto-reselect a just-rerolled daemon.
		if daemon == recomb_reroll_selection:
			recomb_reroll_options.selected = i
		i+=1
	
	_update_using_option_states()
	_update_recomb_reroll_disabled()

## Recombiner

# Disable any options that're equipped. No deleting those.
func _update_using_option_states() -> void:
	for i in recomb_using_options.item_count:
		var daemon := daemon_dictionary[recomb_using_options.get_item_text(i)]
		recomb_using_options.set_item_disabled(i, PlayerData.permanent_daemons.has(daemon) or recomb_reroll_selection == daemon)

func _on_recomb_reroll_selection(index:int) -> void:
	recomb_reroll_selection = daemon_dictionary[recomb_reroll_options.get_item_text(index)] if index >= 0 else null
	
	recomb_reroll_overview.daemon = recomb_reroll_selection if recomb_reroll_selection else null 
	
	_update_using_option_states()
	
	_update_recomb_reroll_disabled()

func _on_recomb_using_selection(index:int) -> void:
	recomb_using_selection = daemon_dictionary[recomb_using_options.get_item_text(index)] if index >= 0 else null
	
	recomb_using_overview.daemon = recomb_using_selection if recomb_using_selection else null 
	
	_update_recomb_reroll_disabled()
	
func _update_recomb_reroll_disabled() -> void:
	recomb_reroll_button.disabled = not (recomb_reroll_selection and recomb_using_selection and not PlayerData.permanent_daemons.has(recomb_using_selection) and recomb_reroll_selection != recomb_using_selection)

func _on_recomb_reroll_pressed() -> void:
	
	# Make sure there's been no mistake.
	_update_recomb_reroll_disabled()
	if recomb_reroll_button.disabled: return
	
	for modifier:Modifier in recomb_reroll_selection.modifiers:
		modifier.percent = modifier._get_new_percent()
	
	Global.daemons_discovered.erase(recomb_using_selection)
	
	_update_discovered_list()
	
	recomb_reroll_overview.daemon = recomb_reroll_selection if recomb_reroll_selection else null 
	recomb_using_overview.daemon = recomb_using_selection if recomb_using_selection else null 

## Injector

func _on_injector_selection(index: int) -> void:
	injector_selection = daemon_dictionary[injector_item_list.get_item_text(index).replace(">", "")]
	
	injector_overview.daemon = injector_selection
	
	injector_equip_button.set_pressed_no_signal(PlayerData.permanent_daemons.has(injector_selection))
	injector_equip_button.disabled = PlayerData.permanent_daemons.size() >= 5 and not PlayerData.permanent_daemons.has(injector_selection)

func _toggle_equip(toggled_on: bool) -> void:
	
	# Toggling and able to select more.
	if toggled_on and PlayerData.permanent_daemons.size() < 5:
		# Equip the selected daemon.
		
		PlayerData.permanent_daemons += [injector_selection]
	
	# Untoggling and this is a selected daemon.
	elif not toggled_on and PlayerData.permanent_daemons.has(injector_selection):
		# Unequip the selected daemon.
		
		PlayerData.permanent_daemons.erase(injector_selection)
	
	injector_equip_button.text = "Equip %s/5" % PlayerData.permanent_daemons.size()
	
	
	for i in injector_item_list.item_count:
		var daemon := daemon_dictionary[injector_item_list.get_item_text(i).replace(">","")]
		
		# Lil ticker > by selected daemons.
		injector_item_list.set_item_text(i, (">" if PlayerData.permanent_daemons.has(daemon) else "") + injector_item_list.get_item_text(i).replace(">", ""))
		
		injector_item_list.set_item_disabled(i, PlayerData.permanent_daemons.size() >= 5 and not PlayerData.permanent_daemons.has(daemon))
	
	_update_using_option_states()

## Hijack ButtonFeedback for sound effects. Heh heh heh.
func _on_input_hover  (..._args:Array) -> void: ButtonFeedback.button_hover_player  .play()
func _on_input_down   (..._args:Array) -> void: ButtonFeedback.button_down_player   .play()
func _on_input_pressed(..._args:Array) -> void: ButtonFeedback.button_pressed_player.play()
