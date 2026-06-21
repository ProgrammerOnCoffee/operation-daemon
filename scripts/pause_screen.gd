class_name PauseScreen extends MarginContainer

var can_pause := false
var is_paused := false

@export var lab:Laboratory
@export var map:WorldMap

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
	
	Global.run_ended.emit()
	
	Global.request_track_transition.emit("Laboratory")
	
	can_pause = false
	
	await TransitionManager.transition_screen(self, lab)
	$GuessWhosFinallyGettingHisPowers.hide()
	await TransitionManager.transition(map, null)
	map._force_finish() # DO NOT leave an instance of combat running. god forbid.

func _on_no_pressed() -> void:
	TransitionManager.transition($GuessWhosFinallyGettingHisPowers, null, true)
