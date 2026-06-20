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
	
	entity_3d.move_to_entity(selected_enemy.entity_3d)
	await get_tree().create_timer(animation_durations.dash - 0.2).timeout
	anim_player.play(animation_names.idle, 0.4)
	await get_tree().create_timer(0.4).timeout
	
	## The target time that the player should respond to the QTE after.
	const PERFECT_QTE_TIME := 0.8 * 3 / 4
	## How long before beginning the attack animation the QTE will be loaded.
	var qte_preload_time := PERFECT_QTE_TIME - attack_point
	var qte: Control
	for i in attack_count:
		if i == 0:
			await get_tree().create_timer(0.1).timeout
			qte = combat_handler.create_qte()
			await get_tree().create_timer(qte_preload_time).timeout
		get_tree().create_timer(attack_point).timeout.connect(entity_3d.play_sound.bind(sound_banks.attack))
		if anim_player.current_animation != animation_names.attack:
			anim_player.play(animation_names.attack, 0.2)
		
		var start_t := Time.get_ticks_msec()
		# Get the base amount of dmg to deal.
		damage_dealing = 0 if qte.has_ended else int(get_damage() * await qte.pressed)
		if damage_dealing:
			# Inflict the relevant effects onto the enemy.
			inflict_effects(selected_enemy, Module.SLOT.ATTACK)
			# Apply the pre-attack effects.
			apply_self_effects(Effect.ApplyType.BEFORE_ATTACK)
			# Do the actual damage to the enemy.
			selected_enemy.take_damage(damage_dealing, true)
			# Recognize the real damage done post-effects.
			damage_dealing = selected_enemy.damage_receiving
			# Apply the post-attack effects.
			apply_self_effects(Effect.ApplyType.AFTER_ATTACK)
			if not selected_enemy.health:
				break
		
		var attack_end_time := animation_durations.attack - (Time.get_ticks_msec() - start_t) * 0.001
		if i == attack_count - 1:
			await get_tree().create_timer(attack_end_time - 0.2).timeout
		else:
			# Load the next QTE before the next attack
			qte = combat_handler.create_qte()
			qte.hide()
			get_tree().create_timer(attack_end_time - qte_preload_time).timeout.connect(qte.fade_in)
			await get_tree().create_timer(attack_end_time).timeout
	
	anim_player.play(animation_names.idle, 0.4)
	
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
