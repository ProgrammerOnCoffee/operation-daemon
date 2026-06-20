extends Control
## Manages the UI for the menu and some other transitions.

@onready var transition_player := $TransitionPlayer

## If [code]true[/code], menu slides are currently being transitioned between.
var is_transitioning: bool


func _ready() -> void:
	if not Engine.is_editor_hint():
		$Splash.show()
		await get_tree().create_timer(1.0).timeout
		Laboratory.input_sound_debounce = false
		TransitionManager.fade($Splash)
	
	if OS.get_name() == "Web":
		$QuitButton.show()


func transition(from_path: NodePath, to_path: NodePath):
	if transition_player.is_playing() or is_transitioning: return
	
	var from_node := get_node(from_path) as Control
	var from_name := from_node.name
	var to_node := get_node(to_path) as Control
	var to_name := to_node.name
	
	const OFFSET = 256
	is_transitioning = true
	#TransitionManager.bar_count = 48
	TransitionManager.fade(from_node)
	TransitionManager.fade(to_node, true)
	#TransitionManager.transition(from_node, to_node)
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	#to_node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	var travel_dir := +1 if (to_name == &"MainMenu" and from_name != &"Credits") or to_name == &"Credits" else -1
	to_node.position.x = -travel_dir * OFFSET * 2
	to_node.modulate.a = 0.0
	
	tween.tween_property(from_node, ^":position:x", travel_dir * OFFSET * 2, 1.0).as_relative()
	tween.tween_property(from_node, ^":modulate:a", 0.0, 0.75)
	tween.tween_property(to_node, ^":position:x", 0 if to_name == &"MainMenu" else -travel_dir * OFFSET, 1.0)
	tween.tween_property(to_node, ^":modulate:a", 1.0, 0.75).set_delay(0.25)
	tween.finished.connect(set.bind(&"is_transitioning", false))
	TransitionManager.bar_count = 24
	
	if transition_player.has_animation(from_name + "<>" + to_name):
		transition_player.play(from_name + "<>" + to_name)
	elif transition_player.has_animation(to_name + "<>" + from_name):
		transition_player.play(to_name + "<>" + from_name, -1, -1.0, true)


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
