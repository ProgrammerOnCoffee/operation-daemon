class_name QTECircle
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

const ATTACK_SPEED = 1.4
const PARRY_SPEED = 1.6

const TARGET_SCALE: float = 0.815
const MAX_SCALE: float = TARGET_SCALE + 0.7
const MIN_SCALE: float = TARGET_SCALE - 0.2
const LENGTH_SCALE = MAX_SCALE - MIN_SCALE
const PERFECT_MARGIN: float = 0.07
const OK_MARGIN: float = 0.14
const ATTACK_PERFECT_DURATION = (MAX_SCALE - TARGET_SCALE) / ATTACK_SPEED
const PARRY_PERFECT_DURATION = (MAX_SCALE - TARGET_SCALE) / PARRY_SPEED

## If [code]true[/code], this QTE is currently running and waiting for player input.
var is_running := false
## If [code]true[/code], this QTE has expired or has been responded to by the player.
var has_ended: bool
## The type of QTE.
var type: Type

## The [Tween] currently fading in/out the QTE.
var _tween: Tween

@onready var marker := $Marker as TextureRect


func _process(delta: float) -> void:
	if visible and is_running:
		#$Tick.rotation += TAU * delta / (0.8 if type == Type.ATTACK else 0.6)
		marker.scale -= Vector2.ONE * delta * (ATTACK_SPEED if type == Type.ATTACK else PARRY_SPEED)
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
			1.0 if s <= TARGET_SCALE + PERFECT_MARGIN and s >= TARGET_SCALE - PERFECT_MARGIN
			else 0.6 if s <= TARGET_SCALE + OK_MARGIN and s >= TARGET_SCALE - OK_MARGIN
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
