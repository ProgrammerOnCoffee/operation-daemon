extends Button
### A button that slides out along with all the usual button feedback.

var tween:Tween

func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)

func _mouse_entered() -> void:
	if tween and tween.is_running(): tween.kill()
	
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	
	tween.tween_property(self, "position:x", 30, 0.05)
	tween.tween_property(self, "scale", Vector2.ONE * 1.04, 0.1)

func _mouse_exited() -> void:
	if tween and tween.is_running(): tween.kill()
	
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	
	tween.tween_property(self, "position:x", 0, 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
