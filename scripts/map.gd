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
		load_entity("slime_spider_bot.tscn")
	add_child(combat_handler)
	ButtonFeedback.setup_recursive(combat_handler)


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
	
	## The [Marker3D] this entity will be placed at.
	var marker := $Markers.get_node(NodePath(marker_name)) as Marker3D
	## The percentage across the [Entity3D]'s viewport the floor level should be.
	var floor_perc := absf(entity.rect.position.y) / entity.rect.size.y
	## The height of the [Entity3D], in meters.
	var height := entity_3d.pixel_size * entity.rect.size.y
	entity_3d.global_position = marker.global_position + Vector3.UP * (height / 2 - height * (1.0 - floor_perc))
	add_child(entity_3d)
