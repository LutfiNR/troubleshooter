extends Panel

@export var mission_tree: Tree
@export var progress_bar: ProgressBar

var progress_value: float = 0.0
var total_count: int = -1


func _ready() -> void:
	NetworkManager.device_updated.connect(_on_device_updated)
	update_progress()


func _on_device_updated(_device_id: String, _device_data: DeviceData) -> void:
	update_progress()


# Update mission completion progress
func update_progress() -> void:
	var tree_data: Dictionary = NetworkManager.mission_checking_result

	var false_count: int = get_false_status_count(tree_data)

	if total_count == -1 and false_count > 0:
		total_count = false_count

	# Perfect completion only if everything is true (i.e. false_count is 0)
	if total_count <= 0:
		progress_value = 0.0
	elif false_count == 0:
		progress_value = 1.0
	else:
		var filled_count = total_count - false_count
		progress_value = clamp(
			float(filled_count) / float(total_count),
			0.0,
			0.99
		)

	progress_bar.value = progress_value * 100.0


# Count all false status values recursively
func get_false_status_count(data: Dictionary) -> int:
	var false_count: int = 0

	for key: Variant in data.keys():
		var value: Variant = data[key]

		if key == "status" and value is bool:
			if not value:
				false_count += 1

		elif value is Dictionary:
			false_count += get_false_status_count(value)

		elif value is Array:
			for item: Variant in value:
				if item is Dictionary:
					false_count += get_false_status_count(item)

	return false_count


func _on_mission_button_toggled(toggled_on: bool) -> void:
	visible = toggled_on
