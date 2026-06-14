extends Control

## Emitted when a command button has been pressed.
## [param command] is the name of the pressed button.
signal command_pressed(command: String)

const RADIUS = 64

## The player [Entity3D] to display this health bar above.
@export var player_3d: Entity3D

@onready var cam := get_viewport().get_camera_3d()


func _ready() -> void:
	update()
	for child in get_children():
		if child is Button:
			child.pressed.connect(_on_command_pressed, CONNECT_APPEND_SOURCE_OBJECT)


func _draw() -> void:
	const COLOR = Color("#444457")
	## The largest scale value of all child buttons.
	var max_scale := minf(maxf(get_child(0).scale.x, get_child(-1).scale.x), 1.0)
	draw_circle(Vector2.ZERO, 8 * max_scale, COLOR * max_scale, false, max_scale * 2, true)
	for i in get_child_count():
		var button := get_child(i) as Button
		var button_scale := minf(button.scale.x, 1.0)
		var points := PackedVector2Array([
			Vector2.UP.rotated(PI / 8 + PI / 8 * 3 * i) * 8,
			(button.position + Vector2(0, button.size.y) + Vector2(-8, 8)) * button_scale,
			(button.position + button.size + Vector2(8, 8)) * button_scale,
		])
		draw_polyline(points, COLOR * button_scale, button_scale * 2, true)
		draw_circle(points[-1], button_scale * 3, COLOR * max_scale, true, -1.0, true)


## Reveals the buttons in the command wheel.
func show_wheel() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_method(queue_redraw.unbind(1), 0, 0, 0.6 + get_child_count() * 0.1)
	for i in get_child_count():
		var b := get_child(i) as Button
		if not b:
			continue
		b.position = (
				Vector2.UP.rotated(PI / 6 + PI / 8 * 3 * i) * RADIUS * Vector2(1, 1.2)
				- Vector2(0, b.size.y) + Vector2.RIGHT * 16)
		b.pivot_offset = -b.position
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
		var b := get_child(i) as Button
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


func _on_command_pressed(source: Button) -> void:
	command_pressed.emit(source.name)
