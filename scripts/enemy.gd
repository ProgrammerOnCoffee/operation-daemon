@tool
class_name Enemy
extends Entity
## An enemy entity in a fight stage.
##
## An enemy entity in a fight stage.


func _take_turn() -> void:
	var player := combat_handler.player
	health_bar.z_index += 1
	entity_3d.move_to_entity(player.entity_3d)
	await get_tree().create_timer(animation_durations.dash - 0.2).timeout
	anim_player.play(animation_names.idle, 0.2)
	await get_tree().create_timer(0.4).timeout
	
	## The target time that the player should respond to the QTE after.
	const PERFECT_QTE_TIME := 0.6 * 3 / 4
	## How long before beginning the attack animation the QTE will be loaded.
	var qte_preload_time := PERFECT_QTE_TIME - attack_point
	var qte: Control
	for i in attack_count:
		if i == 0:
			await get_tree().create_timer(0.1).timeout
			qte = combat_handler.create_qte()
			qte.type = qte.Type.COUNTER if player.is_defending else qte.Type.PARRY
			await get_tree().create_timer(qte_preload_time).timeout
		if sound_banks.attack == "attack_slime_jump":
			entity_3d.play_sound(sound_banks.attack)
		else:
			get_tree().create_timer(attack_point).timeout.connect(entity_3d.play_sound.bind(sound_banks.attack))
		if anim_player.current_animation != animation_names.attack:
			anim_player.play(animation_names.attack, 0.2)
		
		var start_t := Time.get_ticks_msec()
		var value: float = 0.0 if qte.has_ended else await qte.pressed
		if player.is_defending and value > 0.9:
			player.entity_3d.play_sound(sound_banks.counter)
			# Play parry anim
			player.anim_player.play(player.animation_names.parry, 0.2)
			# Return to idle anim after parry
			get_tree().create_timer(player.animation_durations.parry).timeout.connect(player.anim_player.play.bind(player.animation_names.idle, 0.4))
			# Slow down time to add anticipation
			var speed_scale_tween := create_tween()
			speed_scale_tween.tween_property(Engine, ^":time_scale", 0.5, 0.3)
			speed_scale_tween.parallel().tween_property(anim_player, ^":speed_scale", 0.25, 0.3)
			speed_scale_tween.tween_interval(0.2)
			speed_scale_tween.tween_property(anim_player, ^":speed_scale", 1.0, 0.3)
			await speed_scale_tween.finished
			create_tween().tween_property(Engine, ^":time_scale", 1.0, 0.3).set_delay(0.3)
			
			# Figure out how much damage the player's doing.
			combat_handler.player.damage_dealing = int(combat_handler.player.get_damage() * value * 0.5)
			# Apply the player's pre-attack effects.
			combat_handler.player.apply_self_effects(Effect.ApplyType.BEFORE_ATTACK)
			# NOTE: No effects are applied by a Counter/Parry attack.
			# Take the damage.
			take_damage(combat_handler.player.damage_dealing)
			# Apply the player's post-attack effects.
			combat_handler.player.apply_self_effects(Effect.ApplyType.AFTER_ATTACK)
		else:
			if value >= 0.9 and not player.is_defending:
				player.entity_3d.play_sound(sound_banks.parry)
				# Play parry anim
				player.anim_player.play(player.animation_names.parry, 0.2)
				# Return to idle anim after parry
				get_tree().create_timer(0.4).timeout.connect(player.anim_player.play.bind(player.animation_names.idle, 0.2))
				# Slow down time to add anticipation
				var speed_scale_tween := create_tween()
				speed_scale_tween.tween_property(Engine, ^":time_scale", 0.5, 0.15)
				speed_scale_tween.tween_interval(0.3)
				speed_scale_tween.tween_property(Engine, ^":time_scale", 1.0, 0.3)
			
			damage_dealing = (
				get_damage() if player.is_defending # Counter failed, take full damage
				else int(get_damage() * (1.0 - value * 0.5))
			)
			# Inflict the enemy's effects onto the player.
			inflict_effects(combat_handler.player, Module.SLOT.NONE) # Enemy Modules don't have slots.
			# Apply pre-attack effects.
			apply_self_effects(Effect.ApplyType.BEFORE_ATTACK)
			# The player analyzing any daemons it's hit w/.
			Global.research_group(daemons)
			# Do the actual damage.
			combat_handler.player.take_damage(damage_dealing, value < 0.9 or player.is_defending)
			# Recognize the real damage dealt post-effects.
			damage_dealing = combat_handler.player.damage_receiving
			# Apply post-attack effects.
			apply_self_effects(Effect.ApplyType.AFTER_ATTACK)
		
		if not health:
			await get_tree().create_timer(0.7).timeout
			clear()
			await get_tree().create_timer(1.4).timeout
			turn_ended.emit()
			return
		
		var attack_end_time := animation_durations.attack - (Time.get_ticks_msec() - start_t) * 0.001
		if i == attack_count - 1:
			await get_tree().create_timer(attack_end_time - 0.2).timeout
		else:
			# Load the next QTE before the next attack
			qte = combat_handler.create_qte()
			qte.hide()
			get_tree().create_timer(attack_end_time - qte_preload_time).timeout.connect(qte.fade_in)
			await get_tree().create_timer(attack_end_time).timeout
	
	await get_tree().create_timer(0.7).timeout
	await entity_3d.return_to_initial_transform()
	health_bar.z_index -= 1
	turn_ended.emit()
