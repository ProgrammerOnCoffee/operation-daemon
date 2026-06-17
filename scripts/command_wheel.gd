extends Control

## Emitted when a command button has been pressed.
## [param command] is the name of the pressed button.
signal command_pressed(command: String)

## The player [Entity3D] to display this command wheel next to.
@export var player_3d: Entity3D:
	set(value):
		player_3d = value
		update()

@onready var cam := get_viewport().get_camera_3d()


func _ready() -> void:
	update()
	for child in get_children():
		if child is TextureButton:
			child.pivot_offset = -child.position
			child.pressed.connect(_on_command_pressed, CONNECT_APPEND_SOURCE_OBJECT)


## Reveals the buttons in the command wheel.
func show_wheel() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_method(queue_redraw.unbind(1), 0, 0, 0.6 + get_child_count() * 0.1)
	for i in get_child_count():
		var b := get_child(i) as TextureButton
		if not b:
			continue
		b.scale = Vector2.ZERO
		b.self_modulate.a = 0.0
		tween.tween_property(b, ^":scale", Vector2.ONE, 0.6).set_delay(i * 0.1)
		tween.tween_property(b, ^":self_modulate:a", 1.0, 0.4).set_delay(i * 0.1)
		tween.tween_property(b, ^":mouse_filter", MOUSE_FILTER_STOP, 0.5).set_delay(i * 0.1)
	show()


## Hides the buttons in the command wheel.
func hide_wheel() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_method(func(__: int) -> void: queue_redraw(), 0, 0, 0.6 + get_child_count() * 0.1)
	for i in get_child_count():
		var b := get_child(i) as TextureButton
		if not b:
			continue
		b.mouse_filter = MOUSE_FILTER_IGNORE
		b.pivot_offset = -b.position
		tween.tween_property(b, ^":scale", Vector2.ZERO, 0.6).set_delay(i * 0.1)
		tween.tween_property(b, ^":self_modulate:a", 0.0, 0.4).set_delay(i * 0.1)
	await tween.finished
	hide()


## Updates the position of the command wheel, moving it to the position of the
## CommandWheelPoint node in [member player_3d].
func update() -> void:
	if cam and player_3d:
		global_position = cam.unproject_position(
				player_3d.project_point(
						(player_3d.entity.get_node(^"CommandWheelPoint") as Node2D).position
						- Vector2(player_3d.entity.rect.position)
				)
		)


func _on_command_pressed(source: TextureButton) -> void:
	command_pressed.emit(source.name)
