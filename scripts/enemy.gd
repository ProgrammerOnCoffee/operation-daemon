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
	combat_handler.player.take_damage(get_damage())
	await get_tree().create_timer(0.7).timeout
	await entity_3d.return_to_initial_transform()
	turn_ended.emit()
