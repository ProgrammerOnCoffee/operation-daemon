extends Node3D
## A map that a fight will take place in.
##
## A map that a fight will take place in.

static var combat_handler_scene := preload("res://scenes/combat_handler.tscn")

## This map's [CombatHandler] node.
var combat_handler := combat_handler_scene.instantiate() as CombatHandler


func _ready() -> void:
	load_entity("player.tscn")
	
	if OS.has_feature("editor") and get_parent() == get_tree().root:
		# Editor debugging
		var asp := AudioStreamPlayer.new()
		asp.stream = load("res://assets/Music/combat1_79bpm.ogg")
		asp.autoplay = true
		asp.bus = &"Music"
		add_child(asp)
		
		for i in $Markers.get_child_count() - 1:
			load_entity("m_slime.tscn" if i == 2 else "angel.tscn" if i == 1 else "slime_spider_bot.tscn")
	else:
		for i in 1:
			load_enemy()
	
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
		
		# Import other info from PlayerData
		for property in ["health", "max_health", "modules"]:
			entity.set(property, PlayerData.get(property))
		entity.daemons = PlayerData.permanent_daemons
		
	else:
		marker_name = "EnemyMarker%d" % combat_handler.enemies.size()
		combat_handler.enemies.append(entity)
	
	## The [Marker3D] this entity will be placed at.
	var marker := $Markers.get_node(NodePath(marker_name)) as Marker3D
	add_child(entity_3d)
	entity_3d.global_position = marker.global_position - entity_3d.project_point(-entity.rect.position)
	entity_3d.initial_transform = entity_3d.global_transform


## Loads a random enemy from this act's global pool.
func load_enemy() -> void:
	var enemy_3d := Global.pick_enemy()
	## The name of the [Marker3D] this entity will be placed at.
	var marker_name := "EnemyMarker%d" % combat_handler.enemies.size()
	combat_handler.enemies.append(enemy_3d.entity)
	
	## The [Marker3D] this entity will be placed at.
	var marker := $Markers.get_node(NodePath(marker_name)) as Marker3D
	add_child(enemy_3d)
	enemy_3d.global_position = marker.global_position - enemy_3d.project_point(-enemy_3d.entity.rect.position)
	enemy_3d.initial_transform = enemy_3d.global_transform
