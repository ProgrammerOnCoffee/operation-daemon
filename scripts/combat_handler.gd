class_name CombatHandler
extends Node
## Handles the logic for each fight.
##
## Handles the logic for each fight.

## This fight's [Player].
@export var player: Player
## The [Array] of this fight's enemies.
@export var enemies: Array[Enemy]

@onready var cam := get_viewport().get_camera_3d()


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


## Sequentially prompts all entities to take a turn.
func turn() -> void:
	$CommandWheel.show_wheel()
	match await $CommandWheel.command_pressed as String:
		"Attack":
			await $CommandWheel.hide_wheel()
			await player.attack()
		"Special":
			pass
		"Defend":
			pass
	
	var is_enemy_alive := false
	for enemy in enemies:
		if enemy.health:
			is_enemy_alive = true
			await enemy._take_turn()
	
	if not player.health:
		# TODO Lose
		pass
	elif is_enemy_alive:
		turn()
	else:
		# TODO Win, return to map, etc.
		pass
