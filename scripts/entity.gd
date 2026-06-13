class_name Entity
extends CharacterBody2D
## Base class for all entities within a fight.
##
## Base class for the player and all enemies within a fight.

## Emitted when the [Entity]'s turn has ended.
signal turn_ended()

## The base damage this [Entity] deals before effects.
@export var base_damage: int = 10
## The variation applied [member base_damage]. Base damage dealt is equal to
## [code]base_damage + randi_range(-damage_variation, damage_variation)[/code].
@export var damage_variation: int = 1
## This [Entity]'s maximum health.
@export var max_health: int = 100

## This [Entity]'s current health.
var health := max_health:
	set(value):
		value = clampi(value, 0, max_health)
		
		# Update health bar and label
		create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).tween_method(func(h: int) -> void:
			$UI/HealthBar.value = h
			$UI/HealthBar/HealthLabel.text = "%d/%d" % [h, max_health]
		, $UI/HealthBar.value, value, 0.3)
		# TODO add flashing/scaling tween to label when health is <=~10%
		
		health = value
		if health == 0:
			# Kill entity
			pass

@onready var combat_handler := get_parent() as CombatHandler


func _ready() -> void:
	$UI/HealthBar.max_value = max_health
	# Run setter to update health bar and label
	health = health


## Prompts this [Entity] to take its turn.
##[br]
## If this is a [Player], prompts the player to take an action (attack, defend, etc.).
## If this is an [Enemy], attacks the player.
func _take_turn() -> void:
	turn_ended.emit.call_deferred()


## Returns the amount of damage the [Entity] should deal.
func get_damage() -> int:
	return base_damage + randi_range(-damage_variation, damage_variation)


## Makes this [Entity] take [param amount] damage.
func take_damage(amount: int) -> void:
	health -= amount
	var label := $UI/DamageLabel.duplicate() as Label
	label.text = String.num_int64(amount)
	label.velocity = Vector2.UP.rotated(
			randf_range(deg_to_rad(5), deg_to_rad(20))
			* (+1 if randi_range(0, 1) else -1)
	) * 256
	label.show()
	$UI.add_child(label, false, INTERNAL_MODE_BACK)
