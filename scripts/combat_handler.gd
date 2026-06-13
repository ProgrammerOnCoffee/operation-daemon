class_name CombatHandler
extends Node2D
## Handles the logic for each fight.
##
## Handles the logic for each fight.

## This fight's [Player].
@export var player: Player
## The [Array] of this fight's enemies.
@export var enemies: Array[Enemy]


func _ready() -> void:
	turn()


## Sequentially prompts all entities to take a turn.
func turn() -> void:
	player._take_turn()
	await player.turn_ended
	
	var is_enemy_alive := false
	for enemy in enemies:
		if enemy.health:
			is_enemy_alive = true
			enemy._take_turn()
			await enemy.turn_ended
	
	if not player.health:
		# TODO Lose
		pass
	elif is_enemy_alive:
		turn()
	else:
		# TODO Win, return to map, etc.
		pass
