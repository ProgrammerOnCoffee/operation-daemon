class_name Enemy
extends Entity
## An enemy entity in a fight stage.
##
## An enemy entity in a fight stage.


func _ready() -> void:
	super()


func _take_turn() -> void:
	combat_handler.player.take_damage(get_damage())
	await get_tree().create_timer(0.7).timeout
	turn_ended.emit()
