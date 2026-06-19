extends Node3D
## A map that a fight will take place in.
##
## A map that a fight will take place in.

static var combat_handler_scene := preload("res://scenes/combat_handler.tscn")

## This map's [CombatHandler] node.
var combat_handler := combat_handler_scene.instantiate() as CombatHandler


func _ready() -> void:
	load_entity("player.tscn")
	for i in $Markers.get_child_count() - 1:
		load_entity("m_slime_enemy.tscn" if i == 2 else "slime_spider_bot.tscn")
	add_child(combat_handler)
	ButtonFeedback.setup_recursive(combat_handler)
	
	combat_handler.requested_end.connect($EventScene.event_finished.emit)


## Loads an entity and adds it to the map.
func load_entity(file_name: String) -> void:
	var entity := load("res://scenes/entities/" + file_name).instantiate() as Entity
	var entity_3d := Entity3D.new()
	entity_3d.entity = entity
	
	## The name of the [Marker3D] this entity will be placed at.
	var marker_name: String
	if entity is Player:
		marker_name = "PlayerMarker"
		combat_handler.player = entity
	else:
		marker_name = "EnemyMarker%d" % combat_handler.enemies.size()
		combat_handler.enemies.append(entity)
		
		# Give enemy modules and daemons
		for i in randi_range(Global.ACT_MODULES[Global.act * 2 - 2], Global.ACT_MODULES[Global.act * 2 - 1]):
			var effects: Array[Effect]
			for j in randi_range(Global.ACT_EFFECTS[Global.act * 2 - 2], Global.ACT_EFFECTS[Global.act * 2 - 1]):
				var effect := Effect.all_effects.values().pick_random().new() as Effect
				effects.append(effect)
			entity.modules.append(Module.new(effects))
		for k in randi_range(Global.ACT_DAEMONS[Global.act * 2 - 2], Global.ACT_DAEMONS[Global.act * 2 - 1]):
			var modifiers: Array[Modifier]
			# TODO distinguish between positive and negative modifiers
			for l in randi_range(Global.ACT_POS_MODIFIERS[Global.act * 2 - 2], Global.ACT_POS_MODIFIERS[Global.act * 2 - 1]):
				var modifier := Modifier.all_modifiers.values().pick_random().new() as Modifier
				modifiers.append(modifier)
			for m in randi_range(Global.ACT_NEG_MODIFIERS[Global.act * 2 - 2], Global.ACT_NEG_MODIFIERS[Global.act * 2 - 1]):
				var modifier := Modifier.all_modifiers.values().pick_random().new() as Modifier
				modifiers.append(modifier)
			entity.daemons.append(Daemon.new(modifiers))
	
	## The [Marker3D] this entity will be placed at.
	var marker := $Markers.get_node(NodePath(marker_name)) as Marker3D
	add_child(entity_3d)
	entity_3d.global_position = marker.global_position - entity_3d.project_point(-entity.rect.position)
	entity_3d.initial_transform = entity_3d.global_transform
