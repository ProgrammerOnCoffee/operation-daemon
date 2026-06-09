extends Control
## Handles the main menu logic.
##
## Handles the main menu logic.

## If [code]true[/code], menu slides are currently being tweened.
var is_transitioning := false
## The path settings will be saved to.
var settings_path := OS.get_user_data_dir().path_join("data/settings.cfg")

## The value of the ui scale setting.
var ui_scale: float = 1.0:
	set(value):
		get_window().content_scale_factor = value
		ui_scale = value
## If [code]true[/code], VSync is currently enabled.
var vsync_enabled := true:
	set(value):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
		$Settings/ScrollContainer/MarginContainer/GridContainer/VSync.text = "Enabled" if value else "Disabled"
		vsync_enabled = value

## If [code]true[/code], settings are saved.
var _are_settings_saved := true


func _ready() -> void:
	if not Engine.is_editor_hint():
		$Splash.color = ProjectSettings.get_setting("application/boot_splash/bg_color")
		$Splash.show()
	
	# Load settings
	var path := OS.get_user_data_dir() + "/settings.cfg"
	if FileAccess.file_exists(path):
		var config := ConfigFile.new()
		if not config.load(path):
			var music_volume: float = config.get_value("audio", "music_volume", 1.0)
			tween_volume(music_volume, 1)
			$Settings/ScrollContainer/MarginContainer/GridContainer/Music.set_value_no_signal(music_volume)
			var sfx_volume: float = config.get_value("audio", "sfx_volume", 1.0)
			tween_volume(sfx_volume, 2)
			$Settings/ScrollContainer/MarginContainer/GridContainer/SFX.set_value_no_signal(sfx_volume)
			
			ui_scale = config.get_value("graphics", "ui_scale", ui_scale)
			$Settings/ScrollContainer/MarginContainer/GridContainer/UIScale.set_value_no_signal(ui_scale)
			vsync_enabled = config.get_value("graphics", "vsync", vsync_enabled)
			_are_settings_saved = true
	
	$Music.play()
	create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(
			$Splash, ^":modulate:a", 0.0, 1.0).set_delay(0.5).finished.connect($Splash.hide)


func _unhandled_key_input(event: InputEvent) -> void:
	var event_key := event as InputEventKey
	if event_key and event_key.pressed:
		# Focus first valid element if player begins navigating
		# with keyboard or controller but nothing is focused
		if not get_viewport().gui_get_focus_owner() and (
				event_key.is_action(&"ui_up")
				or event_key.is_action(&"ui_down")
				or event_key.is_action(&"ui_left")
				or event_key.is_action(&"ui_right")
		):
			var focus := find_next_valid_focus()
			if focus:
				focus.grab_focus.call_deferred()


## Transitions controls in and out of view.
func transition(from: NodePath, to: NodePath) -> void:
	var from_node := get_node(from)
	var to_node := get_node(to)
	is_transitioning = true
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(from_node, ^":modulate:a", 0.0, 0.4)
	tween.tween_callback(from_node.hide)
	# Set modulate in case node isn't already transparent
	tween.tween_callback(to_node.set.bind(&"modulate", Color.TRANSPARENT))
	tween.tween_callback(to_node.show)
	tween.tween_property(to_node, ^":modulate:a", 1.0, 0.4)
	await tween.finished
	is_transitioning = false


## Tweens the linear volume of an audio [param bus] to [param value].
func tween_volume(value: float, bus: int) -> void:
	create_tween().tween_method(func(x: float) -> void:
		AudioServer.set_bus_volume_linear(bus, x),
		AudioServer.get_bus_volume_linear(bus), value, 0.2)
	_are_settings_saved = false


func _on_play_pressed() -> void:
	transition(^"Menu", ^"Menu")


func _on_settings_back_pressed() -> void:
	transition(^"Settings", ^"Menu")
	if not _are_settings_saved:
		var config := ConfigFile.new()
		var path := OS.get_user_data_dir() + "/settings.cfg"
		config.set_value("audio", "music_volume", AudioServer.get_bus_volume_linear(1))
		config.set_value("audio", "sfx_volume", AudioServer.get_bus_volume_linear(2))
		config.set_value("graphics", "ui_scale", ui_scale)
		config.set_value("graphics", "vsync", vsync_enabled)
		config.save(path)
		_are_settings_saved = true


func _on_ui_scale_value_changed(value: float) -> void:
	ui_scale = value
	_are_settings_saved = false


func _on_vsync_pressed() -> void:
	vsync_enabled = not vsync_enabled
	_are_settings_saved = false
