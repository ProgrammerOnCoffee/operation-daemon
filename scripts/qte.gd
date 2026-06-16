extends TextureRect

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

## If [code]true[/code], this QTE is currently running and waiting for player input.
var is_running := false
## The type of QTE.
var type: Type


func _ready() -> void:
	pressed.connect(prints.bind("Pressed"))


func _process(delta: float) -> void:
	if visible and is_running:
		$Tick.rotation += TAU * delta / (0.8 if type == Type.ATTACK else 0.6)
		if $Tick.rotation_degrees >= 360:
			pressed.emit(0.0)
			fade_out()


func _input(event: InputEvent) -> void:
	if visible and is_running and event.is_action_pressed(&"qte_press"):
		pressed.emit(get_value())
		fade_out()


## Returns the current value that base damage should be multiplied by based on
## how close the QTE tick is to the target area of the ring.
func get_value() -> float:
	var r := wrapf($Tick.rotation_degrees, 0, 360) as float
	return (
			1.0 if r >= 240 and r <= 300
			else 0.7 if r >= 195 and r <= 345
			else 0.0
	)


## Quickly fades in the QTE and begins running it.
func fade_in() -> void:
	show()
	scale = Vector2.ONE * 0.5
	modulate.a = 0.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	tween.tween_property(self, ^":scale", Vector2.ONE, 0.4)
	tween.tween_property(self, ^":modulate:a", 1.0, 0.3)
	tween.tween_property(self, ^":is_running", true, 0.3)


## Quickly fades out the QTE and stops running it.
func fade_out() -> void:
	is_running = false
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	tween.tween_property(self, ^":scale", Vector2.ONE * 1.5, 0.4)
	tween.tween_property(self, ^":modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)
	
	var value := get_value()
	if value >= 0.9 or (type == Type.ATTACK and is_zero_approx(value)):
		(get_parent() as CombatHandler).create_floaty_label(
				global_position + size / 2,
				("Missed!" if is_zero_approx(value) else "Perfect!") if type == Type.ATTACK
				else "Parried!" if type == Type.PARRY else "Countered!"# if type == Type.COUNTER
		).scale *= 0.5
