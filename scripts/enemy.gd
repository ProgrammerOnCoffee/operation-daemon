@tool
class_name Enemy
extends Entity
## An enemy entity in a fight stage.
##
## An enemy entity in a fight stage.


func _take_turn() -> void:
	health_bar.z_index += 1
	await entity_3d.move_to_entity(combat_handler.player.entity_3d)
	
	for i in attack_count:
		await get_tree().create_timer(0.2).timeout
		var qte := combat_handler.create_qte()
		qte.type = qte.Type.COUNTER if combat_handler.player.is_defending else qte.Type.PARRY
		var value: float = await qte.pressed
		if combat_handler.player.is_defending and value > 0.9:
			combat_handler.player.damage_dealing = int(combat_handler.player.get_damage() * value * 0.5)
			apply_effects(Effect.ApplyType.BEFORE_ATTACK, combat_handler.player, self)
			take_damage(combat_handler.player.damage_dealing, combat_handler.player)
			apply_effects(Effect.ApplyType.AFTER_ATTACK, combat_handler.player, self)
		else:
			damage_dealing = (
					get_damage() if combat_handler.player.is_defending # Counter failed, take full damage
					else int(get_damage() * (1.0 - value * 0.5))
			)
			apply_effects(Effect.ApplyType.BEFORE_ATTACK, self, combat_handler.player)
			combat_handler.player.take_damage(damage_dealing, self)
			damage_dealing = combat_handler.player.damage_receiving
			apply_effects(Effect.ApplyType.AFTER_ATTACK, self, combat_handler.player)
	
	await get_tree().create_timer(0.7).timeout
	await entity_3d.return_to_initial_transform()
	health_bar.z_index -= 1
	turn_ended.emit()
