extends Effect

func _get_effect_name() -> String: return "Timebomb"
func _get_description() -> String: return "Every attack applies a bomb, which has a chance of exploding each turn. Every turn it doesn't explode, its damage goes up by %s%. Starts at 3 dmg." % String.num(base * 100)

func _get_effect_color() -> Color: return Color(0.95, 0.427, 0.427, 1.0)
func _get_icon_point_count() -> int: return 4

# Divided by 3 at the end to make this scale less extremely.
# +10 percent w/o the division is an extra 10+ dmg.
func _get_base() -> float: return 1.8 * 3

func _get_target_type() -> Module.TARGET: return Module.TARGET.ATTACKEE
func _is_beneficial() -> bool: return true

func _get_apply_type() -> ApplyType: return ApplyType.BEFORE_ATTACK

var damage := 3.
var turn := 0
func apply_effect(target: Entity) -> bool:
	
	if randf() < 0.6 or turn >= 6:
		# Yes Rico, kaboom.
		print("bakoom -> ", base, "/", pow(base / 3., turn), " to ", target, " turn ", turn)
		target.take_damage(floori(pow(base / 3., turn)))
		return true # No more bomb ._.
	
	turn += 1
	return false
