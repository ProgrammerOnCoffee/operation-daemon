class_name Inventory extends PanelContainer
## Allows for changing which slot modules are on, and viewing permanent daemons.

const MODULE_ENTRY_SCENE := preload("res://scenes/module_entry.tscn")

func _ready() -> void:
	PlayerData.daemons_changed.connect(_update_daemon_list)
	_update_daemon_list()
	
	for i in 10:
		
		var effects:Array[Effect]= []
		for j in 3:
			effects += [Effect.all_effects.values().pick_random().new()]
			
		PlayerData.modules += [Module.new(effects, randi_range(0,2) as Module.SLOT)]
	
	PlayerData.modules_changed.connect(_update_module_list)
	_update_module_list()

## Inventory
@onready var tab_container := $VBoxContainer/TabContainer
@onready var tabs:Dictionary[Module.SLOT, VBoxContainer] = {
	Module.SLOT.NONE:    $VBoxContainer/PanelContainer2/ScrollContainer/VBoxContainer,
	Module.SLOT.ATTACK:  $VBoxContainer/TabContainer/MarginContainer2/HBoxContainer/ScrollContainer/VBoxContainer,
	Module.SLOT.SPECIAL: $VBoxContainer/TabContainer/MarginContainer3/HBoxContainer/ScrollContainer/VBoxContainer
}
var module_entries:Array[ModuleEntry]

func _update_module_list() -> void:
	
	# Yknow what? Reuse the module entries.
	var unused_module_entries := module_entries.duplicate() as Array[ModuleEntry]
	module_entries.clear()
	
	# Childn't
	for tab:Node in tabs.values():
		for child:Node in tab.get_children():
			tab.remove_child(child)
	
	# Find an unused entry or make a new one.
	var find_entry := func() -> ModuleEntry:
		if unused_module_entries.size(): 
			var entry:ModuleEntry = unused_module_entries.pop_front()
			return entry
		
		var new := MODULE_ENTRY_SCENE.instantiate()
		
		module_entries.append(new)
		
		return new
	
	# Add the entries to their tabs, and update them.
	for module in PlayerData.modules:
		var entry := find_entry.call() as ModuleEntry
		
		tabs[module.slot].add_child(entry)
		
		entry._display(module)
	
	# If there are any extra entries, toss 'em.
	for entry in unused_module_entries: entry.queue_free()

## Daemon Overview
@onready var daemon_box      := $VBoxContainer/PanelContainer/HBoxContainer/ScrollContainer/GridContainer
@onready var daemon_overview := $VBoxContainer/PanelContainer/HBoxContainer/DaemonOverview

func _update_daemon_list() -> void:
	
	# Erase existing icons.
	for child in daemon_box.get_children():
		child.queue_free()
	
	# Make the new icons.
	for daemon in PlayerData.permanent_daemons:
		if not daemon: continue
		
		# Make the nodes and add 'em
		var button := Button.new()
		button.flat = true
		var icon := Primitive2D.new()
		
		# Take the first effect's color, and the last's point count.
		icon.modulate = daemon.modifiers.front().effect_type.effect_color
		icon.points   = daemon.modifiers.back() .effect_type.icon_point_count
		
		icon.custom_minimum_size = Vector2.ONE * 28
		button.custom_minimum_size = Vector2.ONE * 28
		button.position = Vector2.ZERO
		
		icon.add_child(button)
		daemon_box.add_child(icon)
		
		# Connect the button to the overview.
		button.pressed.connect(daemon_overview._set_daemon.bind(daemon))
