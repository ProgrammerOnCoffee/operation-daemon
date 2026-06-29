extends Node3D
## A map that a fight will take place in.
##
## A map that a fight will take place in.

static var combat_handler_scene := preload("res://scenes/combat_handler.tscn")

## This map's [CombatHandler] node.
var combat_handler := combat_handler_scene.instantiate() as CombatHandler
## The list of markers that are currently occupied by an entity.
var occupied_markers: Array[Marker3D]
## If [code]true[/code], this is a boss fight.
var is_boss_fight: bool = false


func _ready() -> void:
	load_entity("player.tscn")
	
	if OS.has_feature("editor") and get_parent() == get_tree().root:
		# Editor debugging
		var asp := AudioStreamPlayer.new()
		asp.stream = load("uid://vg4e1772pa46")
		asp.autoplay = true
		asp.bus = &"Music"
		add_child(asp)
		
		if is_boss_fight:
			load_entity("boss.tscn")
			load_entity("angel.tscn")
		else:
			for i in $Markers.get_child_count() - 1:
				load_entity("slime_spider_bot.tscn" if i == 0 else "slime_spider_bot.tscn")
	else:
		if is_boss_fight:
			load_entity("boss.tscn")
			load_enemy()
		else:
			for i in Global.get_weighted_enemy_count():
				load_enemy()
	
	add_child(combat_handler)
	ButtonFeedback.setup_recursive(combat_handler)
	combat_handler.requested_end.connect($EventScene.event_finished.emit)


## Loads an entity and adds it to the map.
func load_entity(file_name: String) -> Entity:
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
		if is_boss_fight and entity.name == &"Boss":
			marker_name = &"EnemyMarker0"
		elif file_name == "tentacle.tscn":
			for i in $TentacleMarkers.get_children():
				if i not in occupied_markers:
					marker_name = i.name
		else:
			for i in $Markers.get_children():
				if i.name != &"PlayerMarker" and i not in occupied_markers:
					marker_name = i.name
		combat_handler.enemies.append(entity)
	
	## The [Marker3D] this entity will be placed at.
	var marker := ($TentacleMarkers if entity_3d.entity.name == &"Tentacle" else $Markers).get_node(NodePath(marker_name)) as Marker3D
	_add_to_occupied_markers(marker)
	entity.died.connect(_remove_from_occupied_markers.bind(marker), CONNECT_ONE_SHOT)
	add_child(entity_3d)
	entity_3d.global_position = marker.global_position - entity_3d.project_point(-entity.rect.position)
	entity_3d.initial_transform = entity_3d.global_transform
	if combat_handler.is_node_ready():
		combat_handler.setup_enemy(entity)
	return entity


## Loads a random enemy from this act's global pool.
func load_enemy() -> void:
	var enemy_3d := Global.pick_enemy()
	## The name of the [Marker3D] this entity will be placed at.
	var marker_name: String
	if enemy_3d.entity.name == &"Tentacle":
		for i in $TentacleMarkers.get_children():
			if i not in occupied_markers:
				marker_name = i.name
	else:
		for i in $Markers.get_children():
			if i.name != &"PlayerMarker" and i not in occupied_markers:
				marker_name = i.name
	combat_handler.enemies.append(enemy_3d.entity)
	
	## The [Marker3D] this entity will be placed at.
	var marker := ($TentacleMarkers if enemy_3d.entity.name == &"Tentacle" else $Markers).get_node(NodePath(marker_name)) as Marker3D
	_add_to_occupied_markers(marker)
	enemy_3d.entity.died.connect(_remove_from_occupied_markers.bind(marker), CONNECT_ONE_SHOT)
	add_child(enemy_3d)
	enemy_3d.global_position = marker.global_position - enemy_3d.project_point(-enemy_3d.entity.rect.position)
	enemy_3d.initial_transform = enemy_3d.global_transform


## Spawns [param n] tentacle enemies.
func spawn_tentacles(n: int) -> void:
	for i in n:
		var entity := load_entity("tentacle.tscn")
		# Skip the turn when the tentacle was spawned
		entity.turns_until_next_turn = 2
		entity.health_bar.modulate.a = 0.0
		Entity.entity_transition_manager.fade(entity, true).connect(func() -> void:
				entity.create_tween().tween_property(entity.health_bar, ^":modulate:a", 1.0, 1.0))
	combat_handler.sort_enemies()


## Returns the number of tentacles that should be spawned.
func get_tentacles_n() -> int:
	var unoccupied_n: int
	for marker in $TentacleMarkers.get_children():
		if marker not in occupied_markers:
			unoccupied_n += 1
	
	var alive_enemy_n: int
	for enemy in combat_handler.enemies:
		if enemy.health:
			alive_enemy_n += 1
	return mini(unoccupied_n, [3, 3, 4].pick_random() - alive_enemy_n)


func _add_to_occupied_markers(marker: Marker3D) -> void:
	occupied_markers.append(marker)
	match marker.name:
		&"TentacleMarker0":
			occupied_markers.append($Markers/EnemyMarker2)
		&"EnemyMarker2":
			occupied_markers.append($TentacleMarkers/TentacleMarker0)
		&"TentacleMarker1":
			occupied_markers.append($Markers/EnemyMarker0)
		&"EnemyMarker0":
			occupied_markers.append($TentacleMarkers/TentacleMarker1)


func _remove_from_occupied_markers(marker: Marker3D) -> void:
	occupied_markers.erase(marker)
	match marker.name:
		&"TentacleMarker0":
			occupied_markers.erase($Markers/EnemyMarker2)
		&"EnemyMarker2":
			occupied_markers.erase($TentacleMarkers/TentacleMarker0)
		&"TentacleMarker1":
			occupied_markers.erase($Markers/EnemyMarker0)
		&"EnemyMarker0":
			occupied_markers.erase($TentacleMarkers/TentacleMarker1)
