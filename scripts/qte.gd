class_name QTE
extends Control

## Emitted when the QTE has been pressed or missed.
## [param value] is how perfectly the event was pressed.
signal pressed(value: float)

## The type of QTE prompt.
enum Type {
	## QTE prompt shown when attacking an enemy.
	ATTACK,
	## QTE prompt shown when parrying an enemy's attack.
	PARRY,
	## QTE prompt shown when countering an enemy's attack.
	COUNTER,
}

## The speed at which attack QTEs will shrink, in scale per second.
const ATTACK_SPEED = 1.5
## The speed at which parry QTEs will shrink, in scale per second.
const PARRY_SPEED = 1.6
## The speed at which counter QTEs will shrink, in scale per second.
const COUNTER_SPEED = 1.7

## The maximum marker scale at which a QTE response will be considered perfect.
const PERFECT_MAX: float = 0.89
## The minimum marker scale at which a QTE response will be considered perfect.
const PERFECT_MIN: float = 0.73
## The maximum marker scale at which a QTE response will be considered OK.
const OK_MAX: float = 1.05
## The minimum marker scale at which a QTE response will be considered OK.
const OK_MIN: float = 0.62

## The exact center of the perfect range, used to time exactly when an attack should occur.
const TARGET_SCALE: float = (PERFECT_MAX + PERFECT_MIN) / 2
## The maximum QTE marker scale (i.e., the initial scale of the marker when the QTE spawns).
const MAX_SCALE: float = OK_MAX + (OK_MAX - PERFECT_MAX) * 4
## The minimum QTE marker scale (i.e., the marker scale at which the QTE will despawn).
const MIN_SCALE: float = OK_MIN #- (PERFECT_MIN - OK_MIN)

## The length of time that a perfect attack QTE will take.
const ATTACK_PERFECT_DURATION = (MAX_SCALE - TARGET_SCALE) / ATTACK_SPEED
## The length of time that a perfect parry QTE will take.
const PARRY_PERFECT_DURATION = (MAX_SCALE - TARGET_SCALE) / PARRY_SPEED
## The length of time that a perfect counter QTE will take.
const COUNTER_PERFECT_DURATION = (MAX_SCALE - TARGET_SCALE) / COUNTER_SPEED

## If [code]true[/code], this QTE is currently running and waiting for player input.
var is_running := false
## If [code]true[/code], this QTE has expired or has been responded to by the player.
var has_ended: bool
## The [enum Type] of QTE.
var type: Type

## The [Tween] currently fading in/out the QTE.
var _tween: Tween

@onready var marker := $Marker as TextureRect


func _process(delta: float) -> void:
	if visible and is_running:
		marker.scale -= Vector2.ONE * delta * (
				ATTACK_SPEED if type == Type.ATTACK
				else PARRY_SPEED if type == Type.PARRY
				else COUNTER_SPEED
		)
		if marker.scale.x <= MIN_SCALE:
			pressed.emit(0.0)
			fade_out()


func _input(event: InputEvent) -> void:
	if visible and is_running and event.is_action_pressed(&"qte_press"):
		pressed.emit(get_value())
		fade_out()


## Returns the current value that base damage should be multiplied by based on
## how close the QTE tick is to the target area of the ring.
func get_value() -> float:
	var s := marker.scale.x as float
	return (
			1.0 if s <= PERFECT_MAX and s >= PERFECT_MIN
			else 0.6 if s <= OK_MAX and s >= OK_MIN
			else 0.0
	)


## Quickly fades in the QTE and begins running it.
func fade_in() -> void:
	$Ring/AnimationPlayer.play(&"Spawn")
	show()
	marker.scale = Vector2.ONE * MAX_SCALE
	marker.modulate.a = 0.0
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	_tween.tween_property(marker, ^":modulate:a", 1.0, 0.25)
	_tween.tween_property(self, ^":is_running", true, 0.25)


## Quickly fades out the QTE and stops running it.
func fade_out() -> void:
	if _tween:
		_tween.kill()
	$Ring/AnimationPlayer.play(&"Despawn")
	has_ended = true
	is_running = false
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_tween.tween_property(marker, ^":modulate:a", 0.0, 0.25)
	_tween.tween_interval(0.05)
	_tween.finished.connect(queue_free)
	
	var value := get_value()
	if value >= 0.9 or (type == Type.ATTACK and is_zero_approx(value)):
		(get_parent() as CombatHandler).create_floaty_label(
				global_position + size / 2,
				("Missed!" if is_zero_approx(value) else "Perfect!") if type == Type.ATTACK
				else "Parried!" if type == Type.PARRY else "Countered!"# if type == Type.COUNTER
		).scale *= 0.5
