extends ColorRect

signal request_begin
signal request_back

@onready var start_button := $HBoxContainer/MarginContainer/VBoxContainer/Button


func _on_start_button_toggled(toggled_on: bool) -> void:
	start_button.text = "RETURN TO LAB" if toggled_on else "BEGIN EXPEDITION"
	
	(request_begin if toggled_on else request_back).emit()
