class_name EffectTooltip extends Control
## A fancy tooltip for Effects.

var char_progress := 0.0

func _ready() -> void:
	get_parent().theme = theme

func _display(effect:Effect):
	$VBoxContainer/MarginContainer/Name.text = effect.effect_name
	$VBoxContainer/MarginContainer/Name.add_theme_color_override("font_color", effect.effect_color)
	
	$VBoxContainer/Description.text = effect.description
	$VBoxContainer/Description.visible_characters = 0

func _process(delta: float) -> void:
	char_progress += delta * 3
	
	$VBoxContainer/Description.visible_characters = lerp(0, $VBoxContainer/Description.get_total_character_count(), char_progress)
