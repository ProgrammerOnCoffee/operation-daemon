@tool
class_name Entity
extends CharacterBody2D
## Base class for all entities within a fight.
##
## Base class for the player and all enemies within a fight.

## Emitted when the [Entity]'s turn has ended.
signal turn_ended()

## This [Entity]'s 2D rect. Used to create a [SubViewport] in 3D scenes and to
## position the [Entity] inside it. In the editor, this is displayed as a red rectangle.
## [br][br]
## [b]Note:[/b] Ensure that extra padding is included to account for this entity's animations.
@export var rect: Rect2i:
	set(value):
		rect = value
		queue_redraw()
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
		
		if health_bar:
			# Update health bar and label
			create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).tween_method(func(h: int) -> void:
				health_bar.get_node(^"HealthBar").value = h
				health_bar.get_node(^"HealthBar/HealthLabel").text = "%d/%d" % [h, max_health]
			, health_bar.get_node(^"HealthBar").value, value, 0.3)
			# TODO add flashing/scaling tween to label when health is <=~10%
		
		health = value
		if health == 0:
			# Kill entity
			pass
## This [Entity]'s [Module]s.
var modules: Array[Module]
## This [Entity]'s [Daemon]s.
var daemons: Array[Daemon]

## The [CombatHandler] node handling this [Entity]'s actions.
var combat_handler: CombatHandler
## The [Entity3D] displaying this [Entity].
var entity_3d: Entity3D
## This [Entity]'s health bar.
var health_bar: Control:
	set(value):
		health_bar = value
		health_bar.get_node(^"HealthBar").max_value = max_health
		health = health


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(rect, Color.RED, false)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Run setter to update health bar and label
	if health_bar:
		health_bar = health_bar
	health = health


## Prompts this [Entity] to take its turn.
##[br]
## If this is a [Player], prompts the player to take an action (attack, defend, etc.).
## If this is an [Enemy], attacks the player.
func _take_turn() -> void:
	turn_ended.emit.call_deferred()


## Returns the array of [Effect]s to apply, based on this entity's [member modules] and [member daemon]s.
func get_effects() -> Array[Effect]:
	## The array of [Effect]s to apply.
	var effects: Array[Effect]
	for module in modules:
		for effect in module.effects:
			effects.append(effect.duplicate())
	for daemon in daemons:
		for modifier in daemon.modifiers:
			for effect in effects:
				if (modifier.modification_type == effect.modification_type
						and modifier.target_type == effect.target_type):
					effect.base *= modifier.percent
	return effects


## Returns the amount of damage the [Entity] should deal.
func get_damage() -> int:
	return base_damage + randi_range(-damage_variation, damage_variation)


## Makes this [Entity] take [param amount] damage.
func take_damage(amount: int) -> void:
	health -= amount
	var label := combat_handler.get_node(^"DamageLabel").duplicate() as Label
	label.global_position = combat_handler.cam.unproject_position(
			entity_3d.project_point(Vector2(rect.size) * Vector2(0.5, 0.25)))
	label.text = String.num_int64(amount)
	label.velocity = Vector2.UP.rotated(
			randf_range(deg_to_rad(5), deg_to_rad(20))
			* (+1 if randi_range(0, 1) else -1)
	) * 256
	label.show()
	combat_handler.add_child(label, false, INTERNAL_MODE_FRONT)
