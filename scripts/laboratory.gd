class_name Laboratory extends ColorRect

signal back_to_main_menu

## If [code]true[/code], no sounds will be played by [method _on_input_hover],
## [method _on_input_down], or [method _on_input_pressed].
static var input_sound_debounce: bool = true

@export var map:Control

@onready var tab_bar          := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/PanelContainer/TabBar
@onready var scroll_container := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer
var goal_scroll_position:float

var daemon_dictionary:Dictionary[String, Daemon] # Turn an ID back into a Daemon.

## Recombiner
@onready var recomb_reroll_options  := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/OptionButton
@onready var recomb_reroll_overview := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DaemonOverview
@onready var recomb_using_options   := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/OptionButton
@onready var recomb_using_overview  := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/DaemonOverview
@onready var recomb_reroll_button   := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Recombiner/VBoxContainer/MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/Button
var recomb_reroll_selection:Daemon
var recomb_using_selection:Daemon

## Injector
@onready var injector_item_list    := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/ItemList
@onready var injector_overview     := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/DaemonOverview
@onready var injector_equip_button := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Injector/VBoxContainer/MarginContainer2/PanelContainer/HBoxContainer/MarginContainer/VBoxContainer/Button
var injector_selection:Daemon

## Logbook
@onready var logbook_tabs    := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Logbook/VBoxContainer/PanelContainer/TabBar
@onready var logbook_title   := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Logbook/VBoxContainer/LogDisplay/MarginContainer/VBoxContainer/Title
@onready var logbook_content := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Logbook/VBoxContainer/LogDisplay/MarginContainer/VBoxContainer/Content
@onready var logbook_overlay := $HBoxContainer/PanelContainer/MarginContainer2/VBoxContainer/ScrollContainer/VBoxContainer/Logbook/CorruptionOverlay
@export  var obscuring_material:ShaderMaterial # Used to make the text illegible
@export_multiline() var logs:Array[String] 
var logs_unlocked := 0

func _ready() -> void:
	
	tab_bar.tab_selected.connect(func(index:int): goal_scroll_position = index * 496)
	
	_update_discovered_list()
	
	$HBoxContainer/PanelContainer/MarginContainer/Button.pressed.connect(func():
		back_to_main_menu.emit()
		Global.request_track_transition.emit("MainMenu", true))
	
	logbook_tabs.clear_tabs()
	# Make a tab for each log.
	for i in logs.size(): logbook_tabs.add_tab("Log %s" % Global.lead(i + 1, 3))
	logbook_tabs.tab_selected.connect(_on_log_selected)
	_on_log_selected(0)
	Global.act_completed.connect(_unlock_log)
	Global.daemon_discovered.connect(_update_discovered_list)

func _process(delta: float) -> void:
	scroll_container.scroll_horizontal = move_toward(scroll_container.scroll_horizontal, goal_scroll_position, 493 * (delta / 0.1)) # Move 493px in 0.1s

func _start_pressed() -> void: 
	# Reset the current act.
	Global.act = 0
	Global.daemon_research.clear()
	
	# Reset the player's health.
	PlayerData.health = PlayerData.max_health
	
	Global.request_track_transition.emit("Map")
	
	TransitionManager.transition_screen(self, map)

func _unlock_log() -> void:
	logs_unlocked += 1
	logbook_tabs.current_tab = logs_unlocked - 1
	_on_log_selected(logs_unlocked - 1)
	Global.push_toast.emit("Log Decrypted: Log %s" % Global.lead(logs_unlocked, 3))

func _on_log_selected(index:int) -> void: 
	
	logbook_title.text = logbook_tabs.get_tab_title(index)
	logbook_content.text = logs[index]
	
	logbook_content.material = null if logs_unlocked > index else obscuring_material
	logbook_overlay.visible =! logs_unlocked > index

func _update_discovered_list(..._args:Array) -> void:
	
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
	recomb_using_selection = null
	
	_update_discovered_list()
	
	#recomb_reroll_options.select(0)
	for i in Global.daemons_discovered.size():
		if Global.daemons_discovered[i] == recomb_reroll_selection: continue
		recomb_using_options.select(i)
		_on_recomb_using_selection(i)
		break
	
	
	
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
func _on_input_hover(..._args:Array) -> void:
	if not input_sound_debounce:
		ButtonFeedback.button_hover_player.play()
func _on_input_down(..._args:Array) -> void:
	if not input_sound_debounce:
		ButtonFeedback.button_down_player.play()
func _on_input_pressed(..._args:Array) -> void:
	if not input_sound_debounce:
		ButtonFeedback.button_pressed_player.play()
