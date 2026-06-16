@tool
class_name Enemy
extends Entity
## An enemy entity in a fight stage.
##
## An enemy entity in a fight stage.


func _take_turn() -> void:
	for effect in get_effects():
		@warning_ignore("incompatible_ternary")
		effect.apply_effect(self if effect.target_type == Module.TARGET.ATTACKER
				else combat_handler.player)
	await entity_3d.move_to_entity(combat_handler.player.entity_3d)
	
	for i in attack_count:
		await get_tree().create_timer(0.2).timeout
		var qte := combat_handler.create_qte()
		qte.type = qte.Type.COUNTER if combat_handler.player.is_defending else qte.Type.PARRY
		var value: float = await qte.pressed
		if combat_handler.player.is_defending:
			if value > 0.9:
				take_damage(int(combat_handler.player.get_damage() * value * 0.5))
			else:
				combat_handler.player.take_damage(int(get_damage()))
		else:
			combat_handler.player.take_damage(int(get_damage() * (1.0 - value * 0.5)))
	
	await get_tree().create_timer(0.7).timeout
	await entity_3d.return_to_initial_transform()
	turn_ended.emit()
