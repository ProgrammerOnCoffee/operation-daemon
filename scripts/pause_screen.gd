class_name PauseScreen extends MarginContainer

var can_pause := false
var is_paused := false

@export var lab:Laboratory

func _process(_delta: float) -> void:
	if can_pause and Input.is_action_just_pressed("pause"):
		
		if is_paused:
			await TransitionManager.transition(self, null, true)
			get_tree().paused = false
			
		else:
			get_tree().paused = true
			TransitionManager.transition(null, self, true)
			
		
		is_paused =! is_paused


func _on_end_run_pressed() -> void:
	TransitionManager.transition(null, $GuessWhosFinallyGettingHisPowers, true)

func _on_confirmation_pressed() -> void:
	
	get_tree().paused = false
	is_paused = false
	
	TransitionManager.transition_screen(self, lab)
	
	Global.run_ended.emit()
	
	can_pause = false


func _on_no_pressed() -> void:
	TransitionManager.transition($GuessWhosFinallyGettingHisPowers, null, true)
