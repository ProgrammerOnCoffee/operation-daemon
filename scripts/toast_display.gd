class_name ToastDisplay extends Control

@export var spacing := 5.
@export var child_template:Control

# Where each child should be, statewise.
var child_tweens:Array[float]
var buffered_toast:Array[String]
var buffer_timer := 0.0

func _ready() -> void:
	Global.daemon_discovered.connect(func(daemon:Daemon): create_buffered_toast("Daemon Discovered: D" + Global.lead(daemon.id, 4)))
	Global.push_toast.connect(create_buffered_toast)

func _process(delta: float) -> void:
	
	#if Input.is_action_just_pressed("qte_press"): for i in 5: create_buffered_toast("?")
	
	var children := get_children()
	
	var summative_size:float = 0
	for i in children.size():
		var child := children[i] as Control
		
		child.position = Vector2(0, summative_size)
		
		if child.size.y > 0:
			summative_size += child.size.y + spacing
	
	buffer_timer += delta
	if buffer_timer > 0.2 and buffered_toast.size() > 0:
		create_toast(buffered_toast.pop_front())
		buffer_timer = 0.0

func create_buffered_toast(text:String): buffered_toast.append(text)

var toast_delay:SceneTreeTimer
func create_toast(text:String):
	
	if toast_delay and not toast_delay.time_left == 0:
		await toast_delay.timeout
	
	var new := child_template.duplicate()
	new.show()
	add_child(new)
	
	new.position.x = -300.
	new.size.y = 40.
	new.modulate.a = 0.
	
	add_child(child_template)
	
	var content := new.get_child(0)
	var label := content.get_child(0).get_child(1) as Label
	label.text = text
	
	var tween := new.create_tween()
	tween.tween_property(new, "position:x", -new.size.x - 20, 0)
	tween.tween_property(new, "position:x", 0.0, 0.2)
	tween.parallel()
	tween.tween_property(new, "modulate:a", 1.0, 0.21)
	tween.tween_interval(4.7)
	tween.tween_property(new, "position:x", -new.size.x - 20, 0.5)
	tween.tween_callback(content.hide)
	
	tween.tween_property(new, "size:y", 0.0, 0.3)
	tween.parallel()
	tween.tween_method(func(_a):new.position.x = -new.size.x - 20, 0, 3, 1.0)
	
	tween.tween_callback(new.queue_free)
	
	toast_delay = get_tree().create_timer(0.2)
