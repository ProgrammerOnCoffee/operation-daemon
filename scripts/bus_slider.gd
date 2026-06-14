extends HSlider

@export var bus_name := &"Master"
@onready var bus_index := AudioServer.get_bus_index(bus_name)

func _ready() -> void:
	value = AudioServer.get_bus_volume_linear(bus_index)

func _value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_linear(bus_index, new_value)
