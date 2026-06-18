@tool
class_name Entity
extends Node2D
## Base class for all entities within a fight.
##
## Base class for the player and all enemies within a fight.

## Emitted when the [Entity]'s turn has ended.
signal turn_ended()

## The [TransitionManager] used to clear entities when killed.
static var entity_transition_manager := TransitionManager.duplicate() as TransitionManager

## This [Entity]'s 2D rect. Used to create a [SubViewport] in 3D scenes and to
## position the [Entity] inside it. In the editor, this is displayed as a red rectangle.
## [br][br]
## [b]Note:[/b] Ensure that extra padding is included to account for this entity's animations.
@export var rect: Rect2i:
	set(value):
		rect = value
		queue_redraw()
## The number of times this entity will attack in a single turn.
@export var attack_count: int = 1
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
			health_bar.get_node(^"Bar").health_p = float(value) / max_health
			var l := health_bar.get_node(^"Bar/Label") as Label
			create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).tween_method(func(h: int) -> void:
				l.text = "%d/%d" % [h, max_health]
			, l.text.substr(0, l.text.length() - 1).to_int(), value, 0.3)
			# TODO add flashing/scaling tween to label when health is <=~10%
		
		health = value
		if self is Player and combat_handler:
			combat_handler.update_player_health_bar()
## This [Entity]'s [Module]s.
var modules: Array[Module]
## This [Entity]'s [Daemon]s.
var daemons: Array[Daemon]
## The [Effects]s currently applied to this [Entity]. Not the same as those they can apply to others.
var current_effects:Array[Effect]
## The amount of damage this entity is about to deal. Used and modified by some effects.
var damage_dealing: int
## The amount of damage this entity is about to receive. Used and modified by some effects.
var damage_receiving: int

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


static func _static_init() -> void:
	entity_transition_manager.bar_count = 48
	entity_transition_manager.random_directions = false
	entity_transition_manager.duration = 0.5
	entity_transition_manager.spread = 0.5
	TransitionManager.add_child(entity_transition_manager)


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
#func get_effects() -> Array[Effect]:
	### The array of [Effect]s to apply.
	#var effects: Array[Effect]
	#for module in modules:
		#for effect in module.effects:
			## Reset modified base back to base
			#effect.modified_base = effect.base
			#effects.append(effect)
	#for daemon in daemons:
		#for modifier in daemon.modifiers:
			#for effect in effects:
				#if modifier.compare_effect(effect) and modifier.target_type == effect.target_type:
					#effect.modified_base *= modifier.percent
	#return effects


## Applied all the [Effect]s currently applied to the entity that match the given [Effect.ApplyType].
func apply_self_effects(apply_type: Effect.ApplyType) -> void:
	for effect in current_effects:
		if effect.apply_type == apply_type:
			# Apply this effect, and remove it if it says to.
			if effect.apply_effect(self):
				current_effects.erase(effect)

## Inflict all the effects from a slot (ATK/SPC) of this entity's onto the player.
func inflict_effects(onto:Entity, filter:Module.SLOT):
	# For every effect from a module in the slot being used to attack
	for module:Module in modules.filter(func(m): return m.slot == filter):
		for effect in module.effects:
			
			# Duplicate the effect.
			var new_effect := effect.duplicate()
			
			# The base should never be changed on the base effect, so the 
			# duplicate's base is already the right value. No modified_base,
			# since this duplicate will never need to calculate its modifiers
			# again.
			
			# Apply all the relevant modifiers.
			for daemon in daemons:
				for modifier in daemon.modifiers:
					if modifier.compare_effect(new_effect):
						new_effect.base *= modifier.percent
			
			# Inflict the effect onto the relevant entities.
			var target := onto if effect.target_type == Module.TARGET.ATTACKEE else self
			
			target.current_effects.append(new_effect)


## Returns the amount of damage the [Entity] should deal.
func get_damage() -> int: 
	return base_damage + randi_range(-damage_variation, damage_variation)


## Makes this [Entity] take [param amount] damage.
func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	
	damage_receiving = amount
	apply_self_effects(Effect.ApplyType.BEFORE_DAMAGE)
	damage_receiving = clampi(damage_receiving, 0, health)
	# Add amount to damage dealt/taken stats
	if self is Player:
		combat_handler.damage_taken += damage_receiving
	else:
		combat_handler.damage_dealt += damage_receiving
	
	health -= amount
	combat_handler.create_floaty_label(
			combat_handler.cam.unproject_position(
					entity_3d.project_point(Vector2(rect.size) * Vector2(0.5, 0.25))
			),
			String.num_int64(amount)
	)
	apply_self_effects(Effect.ApplyType.AFTER_DAMAGE)


## Visually removes this entity from the fight.
func clear() -> void:
	var dir := +1 if self is Player else -1
	entity_transition_manager.angle_min = 210 * dir
	entity_transition_manager.angle_max = 240 * dir
	await entity_transition_manager.fade(self)
	hide()
	entity_3d.hide()
	entity_3d.vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if health_bar:
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(health_bar, ^":modulate:a", 0.0, 0.6)
		tween.finished.connect(health_bar.hide)
