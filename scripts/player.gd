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
	
	await entity_3d.move_to_entity(selected_enemy.entity_3d)
	
	for i in 2:
		await get_tree().create_timer(0.2).timeout
		var qte := combat_handler.get_node(^"QTERing").duplicate() as Control
		qte.anchor_left = randf_range(0.4, 0.6)
		qte.anchor_top = randf_range(0.2, 0.8)
		qte.position -= qte.size / 2
		qte.rotation_degrees = randi_range(-1, 1) * 45
		combat_handler.add_child(qte, false, INTERNAL_MODE_FRONT)
		qte.fade_in()
		selected_enemy.take_damage(int(get_damage() * await qte.pressed))
	
	await get_tree().create_timer(0.7).timeout
	await entity_3d.return_to_initial_transform()
	return true


## Defends from the next attack.
func defend() -> void:
	# TODO
	pass
