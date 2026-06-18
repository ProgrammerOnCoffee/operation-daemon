class_name ModifierLabel extends Label
## A fancy label to display a Modifier.

## The bank of colors to make the text.
const COLOR_BANK = [
	[Color(1.0, 0.32, 0.32, 1.0),  Color(1.0, 0.66, 0.66, 1.0)], # Negative colors, unhovered then hovered.
	[Color(0.32, 1.0, 0.411, 1.0), Color(0.58, 1.0, 0.636, 1.0)]  # Positive colors, unhovered then hovered.
	]

var modifier:Modifier

func _init(for_modifier:Modifier, as_child_of:Node):
	_display(for_modifier)
	as_child_of.add_child(self)

func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited .connect(_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _mouse_entered() -> void: add_theme_color_override("font_color", COLOR_BANK[modifier._is_beneficial() as int][1])
func _mouse_exited()  -> void: add_theme_color_override("font_color", COLOR_BANK[modifier._is_beneficial() as int][0])

func _display(set_modifier:Modifier):
	
	modifier = set_modifier
	
	text = "%s %s" % [percent_as_string(modifier.percent), modifier.effect_type.effect_name]
	
	add_theme_color_override("font_color", COLOR_BANK[modifier._is_beneficial() as int][0])

func percent_as_string(percent:float) -> String:
	var response:String
	
	if percent >= 1.0:
		response += "+"
		percent -= 1.
	else:
		response += "-"
		percent = 1. - percent
	
	response += str(round(percent * 10000) / 100) + "%"
	
	return response

func _get_tooltip(_at_position: Vector2) -> String:
	return "..."
func _make_custom_tooltip(_for_text: String) -> Object:
	var new:EffectTooltip = preload("res://scenes/effect_tooltip.tscn").instantiate()
	
	new._display(modifier.effect_type)
	
	return new
