extends Control
## Manages the UI for the menu and some other transitions.

@onready var transition_player := $TransitionPlayer

func transition(from:NodePath, to:NodePath):
	if transition_player.is_playing(): return
	
	var from_name := get_node(from).name
	var to_name := get_node(to).name
	
	if transition_player.has_animation(from_name + "<>" + to_name):
		transition_player.play(from_name + "<>" + to_name)
	elif transition_player.has_animation(to_name + "<>" + from_name):
		transition_player.play(to_name + "<>" + from_name, -1, -1.0, true)
	else: # No fancy transitions... just use the TM ig... :(
		TransitionManager.transition_screen(get_node(from), get_node(to))
	

func _on_start_pressed() -> void:
	TransitionManager.transition_screen($MainMenu, $Laboratory)
	Global.request_track_transition.emit("Laboratory")
