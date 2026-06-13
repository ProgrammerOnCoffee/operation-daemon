class_name EventButton extends Control
## A fancy button that activates its corresponding Event.

signal pressed

const ICONS:Dictionary[Event.TYPE, Texture2D] = {
	Event.TYPE.NONE:     null,
	Event.TYPE.COMBAT:   preload("res://assets/Enemt Parts/Base_Slime.png"),
	Event.TYPE.REST:     preload("res://assets/Player/Player_Part images/Head.png"),
	Event.TYPE.ANALYSIS: preload("res://assets/Enemt Parts/Machnie_Body_A.png"),
	Event.TYPE.DISEASE:  preload("res://assets/Enemt Parts/Spider_Leg_1_A.png"),
	Event.TYPE.BOSS:     preload("res://assets/Enemt Parts/Spider Leg_2_A.png"),
}

@onready var overlay := $Overlay
@onready var button := $TextureButton

var event :Event: set = set_event
var available := true :set = set_available 

@onready var tween

func _ready() -> void:
	button.pressed.connect(func():
		# Pass the signal.
		pressed.emit()
		
		# Fade in the X overlay
		create_tween().tween_property(overlay, "modulate:a", 1.0, 0.1)
		)

func _mouse_enter() -> void: 
	print("!")
	if available:
		if tween and tween.is_running(): tween.kill()
		
		tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(button, "scale", Vector2.ONE * 1.1, 0.1)
func _mouse_exit() -> void:
	default_tween()

# Reset the tween animation back to its default. Hovering while available is an override.
func default_tween() -> void:
	if tween and tween.is_running(): tween.kill()
	
	# Available - oscillate.
	if available:
		
		tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.set_loops()
		
		tween.tween_property(button, "scale", Vector2.ONE * 0.95, 0.8)
		tween.tween_property(button, "scale", Vector2.ONE * 1.1, 0.8)
		
		print("!")
	
	# Not available. Tween to normal size. 
	else:
		tween = create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.2)

func set_available(to:bool) -> void:
	available = to
	
	default_tween()

## Update all the relevant variables when setting the room data.
func set_event(to:Event) -> void:
	event = to
	
	size = Vector2.ZERO
	
	position = event.position + (size / 2)
	overlay.rotation = randf_range(-PI/14, PI/14)
	
	button.texture_normal = ICONS[event.type]
	#button.size = Vector2.ZERO
	#button.pivot_offset = size / 2
	
	$Label.text = str(event.row)
