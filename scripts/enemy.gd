@tool
class_name Enemy
extends Entity
## An enemy entity in a fight stage.
##
## An enemy entity in a fight stage.

## The number of turns until this [Enemy] will take their next turn.
var turns_until_next_turn: int


## All the Node2Ds that can get modulated by Effect colors.
@onready var colorables:Array[Node2D] = (func() -> Array[Node2D]:
	
	# Recursively search for nodes with 'Color' in the name.
	var search := func(with:Node, function:Callable) -> Array[Node2D]:
		# Can't recursively call a function declared like this, so
		# instead have it passed to itself.
		
		if not with: return []
		
		var array:Array[Node2D]
		
		if with.name.contains("Color"): array += [with]
		
		for child in with.get_children():
			array += function.call(child, function)
		
		return array
	
	return search.call(self, search) ).call()
func _ready() -> void:
	super()
	
	max_health *= Global.ENEMY_HEALTH_COEFFICENTS[Global.act]
	health = max_health
	
	var effects:Array[Effect]
	for module in modules: effects += module.effects
	for node in colorables:
		
		var id := int(node.name.replace("Color ", ""))
		
		if id > effects.size() - 1: return
		
		node.modulate = effects[id].effect_color

func _take_turn() -> void:
	# Check if turn should be skipped
	if turns_until_next_turn:
		turns_until_next_turn -= 1
		if turns_until_next_turn > 0:
			return
	
	var player := combat_handler.player
	if animation_names.dash:
		health_bar.z_index += 1
		entity_3d.move_to_entity(player.entity_3d)
		await get_tree().create_timer(animation_durations.dash - 0.2).timeout
		anim_player.play(animation_names.idle, 0.2)
		await get_tree().create_timer(0.4).timeout
	elif sound_banks.dash:
		entity_3d.play_sound(sound_banks.dash)
	
	if name == &"Boss":
		# Check if any tentacles can be spawned
		var n: int = entity_3d.get_parent().get_tentacles_n()
		if n <= 0:
			# Delay spawn until next turn
			turns_until_next_turn += 1
			return
		
		# Set turns until next wave of tentacles is spawned
		turns_until_next_turn = [3, 4, 4, 5].pick_random()
		# Spawn tentacles
		entity_3d.play_sound(sound_banks.attack)
		anim_player.play(animation_names.attack, 0.2)
		await get_tree().create_timer(animation_durations.attack).timeout
		anim_player.play(animation_names.idle, 1.0)
		entity_3d.get_parent().spawn_tentacles(n)
		await get_tree().create_timer(0.7).timeout
		turn_ended.emit()
		return
	
	## The target time that the player should respond to the QTE after.
	var perfect_qte_time := QTE.COUNTER_PERFECT_DURATION if player.is_defending else QTE.PARRY_PERFECT_DURATION
	## How long before beginning the attack animation the QTE will be loaded.
	var qte_preload_time := perfect_qte_time - attack_point
	var qte: Control
	for i in Global.float_as_chance_int(Global.ENEMY_ATTACK_COUNTS[Global.act] * attack_count):
	
		await get_tree().create_timer(0.1).timeout
		qte = combat_handler.create_qte()
		qte.type = qte.Type.COUNTER if player.is_defending else qte.Type.PARRY
		## The time that the attack animation was begun, as returned by [method Time.get_ticks_msec].
		var start_t: int
		if qte_preload_time > 0:
			if anim_player.current_animation != animation_names.idle:
				await get_tree().create_timer(anim_player.current_animation_length - anim_player.current_animation_position).timeout
			qte.fade_in()
			await get_tree().create_timer(qte_preload_time).timeout
			anim_player.stop()
			anim_player.play(animation_names.attack, 0.2)
			start_t = Time.get_ticks_msec()
		else:
			if anim_player.current_animation != animation_names.idle:
				await get_tree().create_timer(anim_player.current_animation_length - anim_player.current_animation_position).timeout
			anim_player.stop()
			anim_player.play(animation_names.attack, 0.2)
			start_t = Time.get_ticks_msec()
			if name == &"Tentacle":
				var child := get_node(^"Boss_Tent_Ent/Boss Tent_Bones/Bones/Skeleton2D/CHild") as Bone2D
				var dist_to_player := entity_3d.initial_transform.origin.distance_to(combat_handler.player.entity_3d.initial_transform.origin)
				var scale_tween := create_tween()
				scale_tween.tween_interval(0.5)
				scale_tween.tween_property(child, ^":scale", Vector2.ONE * (2.0 if entity_3d.initial_transform.origin.z < combat_handler.player.entity_3d.initial_transform.origin.z else 1.5), 1.7)
				scale_tween.parallel().tween_method(func(p: float) -> void:
					child.position.x = (child.position.x - 38.0) * p + 38.0, 1.0, dist_to_player / 3.2, 1.7)
				scale_tween.tween_property(child, ^":scale", Vector2.ONE * 1.0, 0.7)
				scale_tween.parallel().tween_method(func(p: float) -> void:
					child.position.x = (child.position.x - 38.0) * p + 38.0, dist_to_player / 3.2, 1.0, 0.7)
			await get_tree().create_timer(-qte_preload_time).timeout
			qte.fade_in()
		
		if sound_banks.attack == "attack_slime_jump":
			entity_3d.play_sound(sound_banks.attack)
		else:
			get_tree().create_timer(attack_point + minf(qte_preload_time, 0.0)).timeout.connect(entity_3d.play_sound.bind(sound_banks.attack))
		
		var value: float = 0.0 if (not is_instance_valid(qte)) or qte.has_ended else await qte.pressed
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
			var elapsed_t := (Time.get_ticks_msec() - start_t) * 0.001
			if elapsed_t >= attack_point:
				take_damage(combat_handler.player.damage_dealing, true)
			else:
				get_tree().create_timer(attack_point - elapsed_t).timeout.connect(take_damage.bind(combat_handler.player.damage_dealing, true))
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
			var elapsed_t := (Time.get_ticks_msec() - start_t) * 0.001
			if elapsed_t >= attack_point:
				combat_handler.player.take_damage(damage_dealing, value < 0.9 or player.is_defending)
			else:
				get_tree().create_timer(attack_point - elapsed_t).timeout.connect(combat_handler.player.take_damage.bind(damage_dealing, value < 0.9 or player.is_defending))
			# Recognize the real damage dealt post-effects.
			damage_dealing = combat_handler.player.damage_receiving
			# Apply post-attack effects.
			apply_self_effects(Effect.ApplyType.AFTER_ATTACK)
		
		if not player.health:
			await get_tree().create_timer(0.7).timeout
			turn_ended.emit()
		
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
			# Wait before attacking again
			await get_tree().create_timer(0.5).timeout
	
	await get_tree().create_timer(0.7).timeout
	if animation_names.b_dash:
		await entity_3d.return_to_initial_transform()
		health_bar.z_index -= 1
	else:
		if sound_banks.b_dash:
			entity_3d.play_sound(sound_banks.b_dash)
		anim_player.play(animation_names.idle, 0.4)
	turn_ended.emit()
