class_name CombatHandler
extends Node
## Handles the logic for each fight.
##
## Handles the logic for each fight.

signal requested_end(won:bool)

## Emitted when the player has selected an [Entity] to attack, if any.
signal entity_selected(entity: Entity)
## Emitted when an [Entity] has taken their turn.
signal step_finished(entity: Entity)
## Emitted when every [Entity] has taken their turn and a new turn begins.
signal turn_finished()

## This fight's [Player].
@export var player: Player
## The [Array] of this fight's enemies.
@export var enemies: Array[Enemy]

## The time that this fight started.
var start_time := Time.get_ticks_msec()
## The damage the player has dealt during this fight.
var damage_dealt: int
## The damage the player has taken during this fight.
var damage_taken: int

@onready var cam := get_viewport().get_camera_3d()
## The initial transform of the camera when the fight was loaded.
@onready var _cam_initial_transform := cam.global_transform
## The initial fov of the camera when the fight was loaded.
@onready var _cam_initial_fov := cam.fov

## [member enemies] sorted by each enemy's z position in the [member cam]'s local coordinates.
var _sorted_enemies: Array[Enemy]
## The currently focused [Entity], if any.
var _focused_entity: Entity


func _ready() -> void:
	player.combat_handler = self
	step_finished.connect(get_node(^"PlayerStatus/VBoxContainer/Health/Bar").fade_damaged_p.unbind(1))
	update_player_health_bar()
	$CommandWheel.player_3d = player.entity_3d
	# Add a health bar above every enemy
	const HEALTH_BAR := preload("res://scenes/entity_health_bar.tscn")
	for enemy in enemies:
		enemy.combat_handler = self
		var bar := HEALTH_BAR.instantiate() as Control
		step_finished.connect(bar.get_node(^"Bar").fade_damaged_p.unbind(1))
		bar.entity_3d = enemy.entity_3d
		bar.entity_3d.entity.health_bar = bar
		bar.custom_minimum_size.x = bar.entity_3d.entity.rect.size.x * 0.7
		add_child(bar, false, INTERNAL_MODE_FRONT)
	
	_sorted_enemies = enemies.duplicate()
	_sorted_enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
			return cam.to_local(a.entity_3d.global_position).z <= cam.to_local(b.entity_3d.global_position).z)
	turn()
	
	$EndScreen/MarginContainer/VBoxContainer/Continue.pressed.connect(func():requested_end.emit(player.health))


func _input(event: InputEvent) -> void:
	if _focused_entity:
		if event.is_action_pressed(&"select_right"):
			# Focus next entity
			var index := _sorted_enemies.find(_focused_entity)
			while true:
				index = wrapi(index + 1, 0, _sorted_enemies.size())
				if _sorted_enemies[index].health:
					focus_entity(_sorted_enemies[index])
					break
		elif event.is_action_pressed(&"select_left"):
			# Focus previous entity
			var index := _sorted_enemies.find(_focused_entity)
			while true:
				index = wrapi(index - 1, 0, _sorted_enemies.size())
				if _sorted_enemies[index].health:
					focus_entity(_sorted_enemies[index])
					break
		elif event.is_action_pressed(&"select_confirm"):
			entity_selected.emit(_focused_entity)
		elif event.is_action_pressed(&"select_cancel"):
			entity_selected.emit(null)


## Sequentially prompts all entities to take a turn.
func turn() -> void:
	player.is_defending = false
	while true: # Repeat until player takes action
		$CommandWheel.show_wheel()
		match await $CommandWheel.command_pressed as String:
			"Attack":
				$CommandWheel.hide_wheel()
				if await player.attack():
					break
				$CommandWheel.show_wheel()
			"Special":
				$CommandWheel.hide_wheel()
				if await player.special():
					break
				$CommandWheel.show_wheel()
				break
			"Defend":
				$CommandWheel.hide_wheel()
				player.defend()
				break
	step_finished.emit(player)
	
	var is_enemy_alive := false
	for enemy in enemies:
		if enemy.health and player.health:
			is_enemy_alive = true
			await enemy._take_turn()
			step_finished.emit(enemy)
			if not player.health:
				player.clear()
				break
	
	if player.health and is_enemy_alive:
		turn_finished.emit()
		turn()
	else:
		end_fight()


## Creates a new quick time event prompt.
func create_qte() -> Control:
	var qte := $QTERing.duplicate() as Control
	qte.anchor_left = randf_range(0.4, 0.6)
	qte.anchor_top = randf_range(0.2, 0.7)
	qte.position -= qte.size / 2
	qte.rotation_degrees = randi_range(-1, 1) * 45
	add_child(qte, false, INTERNAL_MODE_FRONT)
	qte.fade_in()
	return qte


## Ends the current fight and displays a win/lose screen.
func end_fight() -> void:
	if player.health:
		$EndScreen/MarginContainer/VBoxContainer/Status.text = "Success"
		$EndScreen/MarginContainer/VBoxContainer/Continue.text = "Return To Map"
	else:
		$EndScreen/MarginContainer/VBoxContainer/Status.text = "Failure"
		$EndScreen/MarginContainer/VBoxContainer/Label.hide()
		$EndScreen/MarginContainer/VBoxContainer/ScrollContainer.hide()
		$EndScreen.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		$EndScreen/MarginContainer/VBoxContainer/Continue.text = "Return To Laboratory"
	
	# Blur background
	$BackBufferCopy.show()
	$Blur.show()
	$Blur.material.set_shader_parameter(&"blur", 0.0)
	create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).tween_method(func(blur: float) -> void:
			$Blur.material.set_shader_parameter(&"blur", blur), 0.0, 2.0, 0.8)
	TransitionManager.fade($EndScreen, true)
	
	var stats_tween := create_tween()
	stats_tween.tween_interval(TransitionManager.duration)
	for l: Label in $EndScreen/MarginContainer/VBoxContainer/Stats.get_children():
		if l.text:
			stats_tween.tween_property(l, ^":text", l.text, 0.3)
			l.text = ""
		else:
			@warning_ignore("integer_division")
			stats_tween.tween_method(_set_stat_text.bind(l), 0,
					damage_dealt if l.name == "Dealt"
					else damage_taken if l.name == "Taken"
					else (Time.get_ticks_msec() - start_time) / 1000, 0.4)
		stats_tween.tween_interval(0.2)


## Prompts the player to select an [Enemy] to attack.
func select_enemy() -> Enemy:
	if player.last_selected_enemy and player.last_selected_enemy.health:
		# Focus last selected enemy
		focus_entity(player.last_selected_enemy)
	else:
		# Focus first alive enemy
		for enemy in enemies:
			if enemy.health:
				focus_entity(enemy)
				break
	var entity := await entity_selected as Entity
	await focus_entity(null)
	return entity


## Animates the camera to focus on [param entity].
## Transitions the camera to its initial position if [param entity] is [code]null[/code].
func focus_entity(entity: Entity) -> void:
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	const D = 0.35
	if entity:
		if not _focused_entity:
			tween.tween_property(cam, ^":fov", _cam_initial_fov * 0.8, D)
		tween.tween_property(cam, ^":global_position",
				_cam_initial_transform.origin.lerp(entity.entity_3d.global_position, 0.4), D)
		tween.tween_property(cam, ^":global_rotation",
				Basis.looking_at(entity.entity_3d.global_position - _cam_initial_transform.origin).get_euler(), D)
	else:
		# Return to initial view
		tween.tween_property(cam, ^":fov", _cam_initial_fov, D)
		tween.tween_property(cam, ^":global_transform", _cam_initial_transform, D)
	_focused_entity = entity
	await tween.finished


## Creates a "floaty" label that gradually spins and falls.
func create_floaty_label(pos: Vector2, text: String) -> Label:
	var label := get_node(^"FloatyLabel").duplicate() as Label
	label.text = text
	label.global_position = pos - label.size / 2
	label.velocity = Vector2.UP.rotated(
			deg_to_rad(randf_range(5, 20))
			* (+1 if randi_range(0, 1) else -1)
	) * 256
	label.show()
	add_child(label, false, INTERNAL_MODE_FRONT)
	return label


## Updates the player's health bar.
func update_player_health_bar() -> void:
	# Update health bar and label
	get_node(^"PlayerStatus/VBoxContainer/Health/Bar").health_p = float(player.health) / player.max_health
	var l := get_node(^"PlayerStatus/VBoxContainer/Health/Label") as Label
	create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).tween_method(func(h: int) -> void:
		l.text = "%d%%" % h
	, l.text.substr(0, l.text.length() - 1).to_int(), player.health, 0.3)


## Sets the text of a label in the stats list to [param x], formatting it according to the type of stat.
func _set_stat_text(x: int, l: Label) -> void:
	@warning_ignore("integer_division")
	l.text = (
			(("%dm " % (x / 60)) if x >= 60 else "") + ("%ds" % (x % 60))
	) if l.name == "Time" else String.num_int64(x)
