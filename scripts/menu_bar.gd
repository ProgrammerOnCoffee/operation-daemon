extends TextureRect

## If [code]true[/code], this bar is currently traveling from right to left.
@export var backwards: bool = false
## The speed that this bar travels, in pixels per second.
@export var speed: float

## The offset relative to the left or right edge that this bar will travel to next.
var target_offset: float
## The offset relative to [member speed] that this bar is currently traveling.
var speed_offset: float

## The bar's initial y position, in UV coordinates.
@onready var initial_y: float = position.y / get_parent().size.y


func _process(delta: float) -> void:
	position.x += (speed + speed_offset) * delta * (-1 if backwards else +1)
	if (position.x <= -size.x - target_offset) if backwards else (position.x >= get_parent().size.x + target_offset):
		if randi_range(0, 1):
			# Start from opposite side
			position.x = get_parent().size.x if backwards else -size.x
		else:
			backwards = not backwards
		flip_h = bool(randi_range(0, 1))
		target_offset = randf() * 64
		speed_offset = randf() * 32
		position.y = initial_y * get_parent().size.y + randf_range(-1.0, 1.0) * 8.0
