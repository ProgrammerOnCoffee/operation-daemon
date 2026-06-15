extends ColorRect

@export var map:Control

func _start_pressed() -> void: 
	# Reset the current act.
	Global.act = 0
	
	TransitionManager.transition_screen(self, map)
	
