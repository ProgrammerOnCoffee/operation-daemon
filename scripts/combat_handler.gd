class_name CombatHandler
extends Node
## Handles the logic for each fight.
##
## Handles the logic for each fight.

## Emitted when the player has selected an [Entity] to attack, if any.
signal entity_selected(entity: Entity)

## This fight's [Player].
@export var player: Player
## The [Array] of this fight's enemies.
@export var enemies: Array[Enemy]

@onready var cam := get_viewport().get_camera_3d()
## The initial transform of the camera when the fight was loaded.
@onready var _cam_initial_transform := cam.global_transform
## The initial fov of the camera when the fight was loaded.
@onready var _cam_initial_fov := cam.fov

## The currently focused [Entity], if any.
var _focused_entity: Entity


func _ready() -> void:
	player.combat_handler = self
	# Add a health bar above every enemy
	const HEALTH_BAR := preload("res://scenes/entity_health_bar.tscn")
	for enemy in enemies:
		enemy.combat_handler = self
		var bar := HEALTH_BAR.instantiate() as Control
		bar.entity_3d = enemy.entity_3d
		bar.entity_3d.entity.health_bar = bar
		bar.custom_minimum_size.x = bar.entity_3d.entity.rect.size.x * 0.7
		add_child(bar, false, INTERNAL_MODE_FRONT)
	turn()


func _input(event: InputEvent) -> void:
	if _focused_entity:
		if event.is_action_pressed(&"select_right"):
			# Focus next entity
			var index := enemies.find(_focused_entity)
			while true:
				index = wrapi(index + 1, 0, enemies.size())
				if enemies[index].health:
					focus_entity(enemies[index])
					break
		elif event.is_action_pressed(&"select_left"):
			# Focus previous entity
			var index := enemies.find(_focused_entity)
			while true:
				index = wrapi(index - 1, 0, enemies.size())
				if enemies[index].health:
					focus_entity(enemies[index])
					break
		elif event.is_action_pressed(&"select_confirm"):
			entity_selected.emit(_focused_entity)
		elif event.is_action_pressed(&"select_cancel"):
			entity_selected.emit(null)


## Sequentially prompts all entities to take a turn.
func turn() -> void:
	while true: # Repeat until player takes action
		$CommandWheel.show_wheel()
		match await $CommandWheel.command_pressed as String:
			"Attack":
				$CommandWheel.hide_wheel()
				if await player.attack():
					break
				$CommandWheel.show_wheel()
			"Special":
				break
			"Defend":
				break
	
	var is_enemy_alive := false
	for enemy in enemies:
		if enemy.health and player.health:
			is_enemy_alive = true
			await enemy._take_turn()
	
	if player.health and is_enemy_alive:
		turn()
	else:
		end_fight()


## Ends the current fight and displays a win/lose screen.
func end_fight() -> void:
	if player.health:
		$EndScreen/MarginContainer/VBoxContainer/Status.text = "Success"
	else:
		$EndScreen/MarginContainer/VBoxContainer/Status.text = "Failure"
	# TODO show stats etc.
	TransitionManager.fade($EndScreen, true)


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
