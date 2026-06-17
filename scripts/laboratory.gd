extends ColorRect

@export var map:Control

@onready var tab_bar          := $HBoxContainer/MarginContainer2/VBoxContainer/PanelContainer/TabBar
@onready var scroll_container := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer
var goal_scroll_position:float

## Injector
@onready var injector_item_list    := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/ItemList
@onready var injector_overview     := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/DaemonOverview
@onready var injector_equip_button := $HBoxContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/Button
var injector_dictionary:Dictionary[String, Daemon] # Turn an ID back into a Daemon.
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

## Injector

func _update_discovered_list() -> void:
	injector_item_list.clear()
	
	for daemon in Global.daemons_discovered:
		var id := "D%s" % Global.lead(daemon.id, 4)
		
		injector_dictionary[id] = daemon
		
		injector_item_list.add_item(id)

func _on_injector_selection(index: int) -> void:
	injector_selection = injector_dictionary[injector_item_list.get_item_text(index).replace(">", "")]
	
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
		var daemon := injector_dictionary[injector_item_list.get_item_text(i).replace(">","")]
		
		# Lil ticker > by selected daemons.
		injector_item_list.set_item_text(i, (">" if PlayerData.permanent_daemons.has(daemon) else "") + injector_item_list.get_item_text(i).replace(">", ""))
		
		injector_item_list.set_item_disabled(i, PlayerData.permanent_daemons.size() >= 5 and not PlayerData.permanent_daemons.has(daemon))

## Hijack ButtonFeedback for sound effects. Heh heh heh.
func _on_input_hover  (..._args:Array) -> void: ButtonFeedback.button_hover_player  .play()
func _on_input_down   (..._args:Array) -> void: ButtonFeedback.button_down_player   .play()
func _on_input_pressed(..._args:Array) -> void: ButtonFeedback.button_pressed_player.play()
	
