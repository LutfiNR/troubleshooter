class_name ClickResolver
extends Node

static func is_topmost(target_area: Area2D) -> bool:
	var areas: Array[Area2D] = _get_clicked_areas(target_area)
	return not areas.is_empty() and areas.front() == target_area


static func _get_clicked_areas(context: Node) -> Array[Area2D]:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = context.get_global_mouse_position()
	query.collide_with_areas = true
	
	var results: Array = context.get_world_2d().direct_space_state.intersect_point(query)

	var areas: Array[Area2D] = []

	for hit in results:
		if hit.collider is Area2D and hit.collider.name == "InteractArea":
			areas.append(hit.collider)

	areas.sort_custom(_sort_by_y_descending)

	return areas


static func _sort_by_y_descending(a: Area2D, b: Area2D) -> bool:
	return a.global_position.y > b.global_position.y
