extends Panel

@export var mission_tree: Tree
@export var progress_bar: ProgressBar

var progress_value: float = 0.0


func _ready() -> void:
	NetworkDeviceManager.device_updated.connect(_on_device_updated)
	update_progress()


func _on_device_updated(_device_id: String) -> void:
	update_progress()


# Update mission completion progress
func update_progress() -> void:
	var tree_data: Dictionary = MissionManager.get_mission_tree_data()

	var status_result: Dictionary = get_status_count(tree_data)

	var true_count: int = status_result.true_count
	var false_count: int = status_result.false_count
	var total_count: int = true_count + false_count

	# Perfect completion only if everything is true
	if total_count == 0:
		progress_value = 0.0
	elif false_count == 0:
		progress_value = 1.0
	else:
		progress_value = min(
			float(true_count) / float(total_count),
			0.99,
		)

	progress_bar.value = progress_value * 100.0


# Count all true/false status values recursively
func get_status_count(data: Dictionary) -> Dictionary:
	var true_count: int = 0
	var false_count: int = 0

	for key: Variant in data.keys():
		var value: Variant = data[key]

		if key == "status" and value is bool:
			if value:
				true_count += 1
			else:
				false_count += 1

		elif value is Dictionary:
			var result: Dictionary = get_status_count(value)

			true_count += result.true_count
			false_count += result.false_count

		elif value is Array:
			for item: Variant in value:
				if item is Dictionary:
					var result: Dictionary = get_status_count(item)

					true_count += result.true_count
					false_count += result.false_count

	return {
		"true_count": true_count,
		"false_count": false_count,
	}


func _on_mission_button_toggled(toggled_on: bool) -> void:
	visible = toggled_on
