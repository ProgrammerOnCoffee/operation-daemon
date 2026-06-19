@tool
extends Control

var label:Label

func _ready() -> void:
	for child in get_children():
		if child is Label: 
			label = child
			return
	
	label = Label.new()
	add_child(label)
	label.owner = owner

func _process(delta: float) -> void:
	label.size = Vector2.ZERO
	size = Vector2(label.size.y, label.size.x)
	label.position = Vector2(0, label.size.x)
	
