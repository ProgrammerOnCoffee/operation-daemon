@tool
class_name Player
extends Entity
## The player entity in a fight stage.
##
## The player entity in a fight stage.


## Attacks an [Enemy].
func attack() -> void:
	var effects := get_effects()
	
	if combat_handler.enemies.size() > 1:
		# TODO select which enemy to attack
		for enemy in combat_handler.enemies:
			if enemy.health:
				for effect in effects:
					@warning_ignore("incompatible_ternary")
					effect.apply_effect(self if effect.target_type == Module.TARGET.ATTACKER else enemy)
				enemy.take_damage(get_damage())
				break
	else:
		for effect in effects:
			@warning_ignore("incompatible_ternary")
			effect.apply_effect(
					self if effect.target_type == Module.TARGET.ATTACKER
					else combat_handler.enemies[0])
		combat_handler.enemies[0].take_damage(get_damage())
	await get_tree().create_timer(0.7).timeout


## Defends from the next attack.
func defend() -> void:
	# TODO
	pass
