@tool
class_name EffectTooltip extends Control
## A fancy tooltip for Effects.

## Overrides for the text sizes.
@export var title_text_size := -1:
	set(to):
		title_text_size = to
		$VBoxContainer/MarginContainer/Name.add_theme_font_size_override("font_size", title_text_size)
@export var description_text_size := -1:
	set(to):
		description_text_size = to
		$VBoxContainer/Description.add_theme_font_size_override("font_size", description_text_size)

var char_progress := 0.0

func _ready() -> void:
	get_parent().theme = theme
	
	if description_text_size > 0:
		$VBoxContainer/Description.add_theme_font_size_override("font_size", description_text_size)
	if title_text_size > 0:
		$VBoxContainer/MarginContainer/Name.add_theme_font_size_override("font_size", title_text_size)

func _display(effect:Effect):
	$VBoxContainer/MarginContainer/Name.text = effect.effect_name
	$VBoxContainer/MarginContainer/Name.add_theme_color_override("font_color", effect.effect_color)
	
	$VBoxContainer/Description.text = effect.description
	$VBoxContainer/Description.visible_characters = 0

func _process(delta: float) -> void:
	char_progress += delta * 3
	
	$VBoxContainer/Description.visible_characters = lerp(0, $VBoxContainer/Description.get_total_character_count(), char_progress)
