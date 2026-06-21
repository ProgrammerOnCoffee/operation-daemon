extends HSlider

@export var bus_name := &"Master"
@onready var bus_index := AudioServer.get_bus_index(bus_name)

func _ready() -> void:
	value = AudioServer.get_bus_volume_linear(bus_index)
	
	Global.setting_changed.connect(_setting_changed)

func _setting_changed(n:String,t:Variant): if n == "Audio" + bus_name:
	set_value_no_signal(t)

func _value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_linear(bus_index, new_value)
	
	Global.setting_changed.emit("Audio" + bus_name, new_value)
