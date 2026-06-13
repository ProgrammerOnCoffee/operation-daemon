extends Label
## A [Label] that displays the damage dealt to an [Entity].
##
## A [Label] that displays the damage dealt to an [Entity]. Gradually rotates and
## moves according to its [member rot_velocity] and [member velocity].

## The label's velocity.
var velocity: Vector2
## The label's rotational velocity, in radians.
var rot_velocity: float = randf_range(deg_to_rad(10), deg_to_rad(25)) * (+1 if randi_range(0, 1) else -1)


func _ready() -> void:
	if visible:
		# Gradually fade out label
		var tween := create_tween().set_parallel()
		tween.tween_property(self, ^":self_modulate:a", 0.0, 0.5).set_delay(0.2)
		tween.finished.connect(queue_free)


func _process(delta: float) -> void:
	if visible:
		rotation += rot_velocity * delta
		# Add gravity
		velocity.y += 980 * delta
		position += velocity * delta
