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
## The bank of sounds all entities will pull from. Each key is the name of a set
## of sounds, and each value is either an [Array][[AudioStream]] of sounds, or
## an [Array][[Array]] where the first element is an [AudioStream] and the second
## is a configuration dictionary.
static var sounds: Dictionary[String, Array] = {
	"attack_angel": [
		load("uid://cvlill150y258"),
		load("uid://cb53vtqpu72e5"),
	],
	"attack_goopy_plane": [
		[load("uid://eag2q5dt6aha"), { "pitch_scale": 2.0 }],
		[load("uid://pnu66jqjsg4n"), { "pitch_scale": 2.0 }],
	],
	"attack_robot": [
		load("uid://d07y23uo215bm"),
		load("uid://b2swg85mx460"),
		load("uid://dx71ea4fmtwlw"),
	],
	"attack_slime": [
		load("uid://dj4qgyt14tiah"),
	],
	"attack_slime_jump": [
		[load("uid://dmmwsm2wny11e"), { "next_sound": "slime_land", "next_delay": 0.55 }],
	],
	"counter": [
		load("uid://cpxylalf4b0r1"),
	],
	"dash_angel": [
		load("uid://c7jh7peverb58"),
	],
	"b_dash_angel": [
		load("uid://pml0ebyl72ut"),
	],
	"dash_goopy_plane": [
		load("uid://bvvbjybeytkb"),
	],
	"dash_robot": [
		[load("uid://dof1kxqge0x7i"), { "volume": -6.0 }],
	],
	"dash_slime": [
		[load("uid://5nwkunvbj4ma"), { "next_sound": "dash_slime", "next_delay": 0.6, "next_count": 2, "volume": -3.0 }],
		[load("uid://c20iy386aq0q4"), { "next_sound": "dash_slime", "next_delay": 0.6, "next_count": 2 }],
	],
	"dash_slime_jump": [
		[load("uid://dmmwsm2wny11e"), { "next_sound": "slime_land", "next_delay": 0.85 }],
	],
	"dash_spider": [
		load("uid://bragk1mdh5ysw"),
	],
	"b_dash_spider": [
		[load("uid://by3xroc14dams"), { "volume": -9.0 }],
	],
	"death_goopy_plane": [
		load("uid://c07wpp23qds51"),
		load("uid://0qbhthnhgdxa"),
		load("uid://c8jwmbykiv6x8"),
	],
	"death_robot": [
		load("uid://c8ajt4e1vtu52"),
	],
	"death_slime": [
		load("uid://lyg48wyatxgy"),
		load("uid://bc51ptet4ko3c"),
	],
	"hit_robot": [
		load("uid://bbfcxfi4ihw2b"),
		load("uid://cs5vvdsdfntli"),
		load("uid://dvq6ybkysicfn"),
		load("uid://ckf4vbwakyq0e"),
	],
	"hit_goopy_plane": [
		load("uid://dc52y5q3ryf73"),
		load("uid://du12omanop5ak"),
	],
	"hit_slime": [
		load("uid://bhfv6fc13tgds"),
		load("uid://bhx5uotn6s1ll"),
	],
	"parry": [
		load("uid://s6dhybv0qbv"),
	],
	"slime_land": [
		load("uid://cqc3xnrcka1oi"),
	],
}

## This [Entity]'s 2D rect. Used to create a [SubViewport] in 3D scenes and to
## position the [Entity] inside it. In the editor, this is displayed as a red rectangle.
## [br][br]
## [b]Note:[/b] Ensure that extra padding is included to account for this entity's animations.
@export var rect: Rect2i:
	set(value):
		rect = value
		queue_redraw()
## The additional distance (in pixels) that the entity should be moved towards
## other entities when attacking them.
## [br]
## By default, entities are moved towards each other so that the edges of their
## viewports overlap. [member rect] is usually wider than the entity's regular
## stance to keep animations like attack from clipping outside of the viewport,
## so increase this value in order to move entities closer to each other and
## make their attacks seem to actually hit each other.
@export var rect_attack_inset: int
## The number of times this entity will attack in a single turn.
@export var attack_count: int = 1
## The base damage this [Entity] deals before effects.
@export var base_damage: int = 10
## The variation applied [member base_damage]. Base damage dealt is equal to
## [code]base_damage + randi_range(-damage_variation, damage_variation)[/code].
@export var damage_variation: int = 1
## This [Entity]'s maximum health.
@export var max_health: int = 100

## The map of common sound bank names to the name of the actual bank in
## [member sounds] this entity will pull sounds from.
@export var sound_banks: Dictionary[StringName, String] = {
	"attack": "attack_robot",
	"b_dash": "dash_robot",
	"counter": "counter",
	"dash": "dash_robot",
	"death": "death_robot",
	"hit": "hit_robot",
	"parry": "parry",
}

@export_group("Animations")
## The map of common animation names to the actual name of the animation in the animation data.
@export var animation_names: Dictionary[StringName, StringName] = {
	"attack": &"Attack",
	"b_dash": &"BDash",
	"damaged": &"Damaged",
	"dash": &"Dash",
	"death": &"Death",
	"idle": &"Idle",
	"parry": &"Parry",
}
## The map of common animation names to the duration they should take in-game.
@export var animation_durations: Dictionary[StringName, float] = {
	"attack": 1.0,
	"b_dash": 1.0,
	"damaged": 1.0,
	"dash": 1.0,
	"death": 1.0,
	"idle": 1.0,
	"parry": 1.0,
}
## The exact point during the entity's attack animation that the entity attacks.
## Used to time QTEs and determine when the player has responded to them perfectly.
@export var attack_point: float

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
			, l.text.substr(0, l.text.find("/")).to_int(), value, 0.3)
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
## This [Entity]'s [AnimationPlayer] node.
var anim_player: AnimationPlayer
## The [Entity3D] displaying this [Entity].
var entity_3d: Entity3D
## This [Entity]'s health bar.
var health_bar: Control:
	set(value):
		health_bar = value
		health = health


static func _static_init() -> void:
	entity_transition_manager.bar_count = 48
	entity_transition_manager.random_directions = false
	entity_transition_manager.duration = 0.5
	entity_transition_manager.spread = 0.5
	TransitionManager.add_child(entity_transition_manager)


func _draw() -> void:
	if Engine.is_editor_hint():
		var x := rect.position.x + (rect_attack_inset if self is Enemy else rect.size.x - rect_attack_inset)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), Color.BLUE)
		draw_rect(rect, Color.RED, false)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Find entity's [AnimationPlayer] dynamically
	var queue := get_children()
	while queue:
		var new_queue: Array[Node]
		for child in queue:
			if child is AnimationPlayer:
				anim_player = child
				break
			new_queue.append_array(child.get_children())
		queue = new_queue
	
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
func take_damage(amount: int, animate: bool = false) -> void:
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
	
	health -= damage_receiving
	combat_handler.create_floaty_label(
			combat_handler.cam.unproject_position(
					entity_3d.project_point(Vector2(rect.size) * Vector2(0.5, 0.25))
			),
			String.num_int64(amount)
	)
	apply_self_effects(Effect.ApplyType.AFTER_DAMAGE)
	
	if health:
		if animate:
			entity_3d.play_sound(sound_banks.hit)
			if anim_player.current_animation == animation_names.idle:
				get_tree().create_timer(animation_durations.damaged).timeout.connect(anim_player.play.bind(animation_names.idle, 03))
			anim_player.play(animation_names.damaged, 0.1)
	else:
		entity_3d.play_sound(sound_banks.death)
		anim_player.play(animation_names.death, 0.1)


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
