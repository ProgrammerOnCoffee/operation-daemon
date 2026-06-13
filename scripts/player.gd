@tool
class_name Player
extends Entity
## The player entity in a fight stage.
##
## The player entity in a fight stage.

## Emitted after the player has taken an action (attack, defend, etc.).
signal action_taken(action: String)


func _ready() -> void:
	super()


func _take_turn() -> void:
	$UI/Controls.show()
	await action_taken
	turn_ended.emit()


## Attacks an [Enemy].
func attack() -> void:
	$UI/Controls.hide()
	if combat_handler.enemies.size() > 1:
		# TODO select which enemy to attack
		pass
	else:
		combat_handler.enemies[0].take_damage(get_damage())
	await get_tree().create_timer(0.7).timeout
	action_taken.emit("Attack")


## Defends from the next attack.
func defend() -> void:
	action_taken.emit("Defend")
