@tool
class_name Player
extends Entity
## The player entity in a fight stage.
##
## The player entity in a fight stage.

## The last [Enemy] the player selected to attack.
var last_selected_enemy: Enemy
## If [code]true[/code], the player is currently in a defensive state and can counter attacks.
var is_defending: bool


## Attacks an [Enemy]. Returns whether or not the attack was completed.
func attack() -> bool:
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
		
		# Fade health bar for all enemies other than selected enemy
		var fade_bar_out_tween: Tween
		for enemy in combat_handler.enemies:
			if enemy != selected_enemy:
				if not fade_bar_out_tween:
					fade_bar_out_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_parallel()
				fade_bar_out_tween.tween_property(enemy.health_bar, ^":modulate:a", 0.0, 0.3)
	else:
		selected_enemy = combat_handler.enemies[0]
	last_selected_enemy = selected_enemy
	
	await entity_3d.move_to_entity(selected_enemy.entity_3d)
	
	for i in attack_count:
		await get_tree().create_timer(0.2).timeout
		var qte := combat_handler.create_qte()
		damage_dealing = int(get_damage() * await qte.pressed)
		apply_effects(Effect.ApplyType.BEFORE_ATTACK, self, selected_enemy)
		selected_enemy.take_damage(damage_dealing, self)
		damage_dealing = selected_enemy.damage_receiving
		apply_effects(Effect.ApplyType.AFTER_ATTACK, self, selected_enemy)
	
	# Fade health bar back in for all enemies other than selected enemy
	var fade_bar_in_tween: Tween
	for enemy in combat_handler.enemies:
		if enemy != selected_enemy:
			if not fade_bar_in_tween:
				fade_bar_in_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_parallel()
				fade_bar_in_tween.tween_interval(1.0)
				fade_bar_in_tween.chain()
			fade_bar_in_tween.tween_property(enemy.health_bar, ^":modulate:a", 1.0, 0.3)
	
	await get_tree().create_timer(0.7).timeout
	await entity_3d.return_to_initial_transform()
	if not selected_enemy.health:
		selected_enemy.clear()
	return true


## Attacks an [Enemy] with the player's special attack.
## Returns whether or not the special was completed.
func special() -> bool:
	# TODO
	return await attack()


## Gives the player a chance to counter enemies' attacks.
func defend() -> void:
	is_defending = true
