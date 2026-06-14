@tool
class_name Player
extends Entity
## The player entity in a fight stage.
##
## The player entity in a fight stage.

## The last [Enemy] the player selected to attack.
var last_selected_enemy: Enemy


## Attacks an [Enemy]. Returns whether or not the attack was completed.
func attack() -> bool:
	var effects := get_effects()
	
	## The enemy the player has selected to attack.
	var selected_enemy: Enemy
	if combat_handler.enemies.size() > 1:
		var alive_enemies: Array[Enemy]
		for enemy in combat_handler.enemies:
			if enemy.health:
				alive_enemies.append(enemy)
		if alive_enemies.size() > 1:
			selected_enemy = await combat_handler.select_enemy()
			if not selected_enemy:
				return false
		else:
			selected_enemy = alive_enemies[0]
	else:
		selected_enemy = combat_handler.enemies[0]
	last_selected_enemy = selected_enemy
	
	for effect in effects:
		@warning_ignore("incompatible_ternary")
		effect.apply_effect(
				self if effect.target_type == Module.TARGET.ATTACKER
				else selected_enemy)
	selected_enemy.take_damage(get_damage())
	await get_tree().create_timer(0.7).timeout
	return true


## Defends from the next attack.
func defend() -> void:
	# TODO
	pass
