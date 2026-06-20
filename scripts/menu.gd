extends Control
## Manages the UI for the menu and some other transitions.

@onready var transition_player := $TransitionPlayer

## If [code]true[/code], menu slides are currently being transitioned between.
var is_transitioning: bool


func _ready() -> void:
	if not Engine.is_editor_hint():
		$Splash.show()
		await get_tree().create_timer(1.0).timeout
		TransitionManager.fade($Splash)
	
	if OS.get_name() == "Web":
		$QuitButton.show()


func transition(from:NodePath, to:NodePath):
	if transition_player.is_playing() or is_transitioning: return
	
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


func _on_quit_pressed() -> void:
	is_transitioning = true
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(v: float) -> void:
			AudioServer.set_bus_volume_linear(0, v), AudioServer.get_bus_volume_linear(0), 0.0, 3.0)
	tween.parallel().tween_property($Splash, ^":modulate:v", 0.0, 1.5).set_delay(1.0)
	TransitionManager.fade($Splash, true)
	await tween.finished
	get_tree().quit()
