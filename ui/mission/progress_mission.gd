extends ProgressBar

var progress_value: float = 0.0
var total_count: int = -1

func _ready() -> void:
	NetworkManager.devices_initialized.connect(_on_devices_initialized)
	NetworkManager.device_updated.connect(_on_device_updated)

func _on_devices_initialized() -> void:
	setup_progress()

func _on_device_updated(_device_id: String, _device_data: DeviceData) -> void:
	update_progress()

func setup_progress()-> void:
	var tree_data: Dictionary = NetworkManager.mission_checking_result
	var false_count: int =  get_false_status_count(tree_data)
	if total_count == -1 and false_count > 0:
			total_count = false_count
			
func update_progress() -> void:
	var tree_data: Dictionary = NetworkManager.mission_checking_result
	var false_count: int =  get_false_status_count(tree_data)
	if total_count < 0:
		progress_value = 1.0
	else:
		var filled_count = total_count - false_count
		var prev_value = progress_value
		progress_value = clamp(
			float(filled_count) / float(total_count),
			0.0,
			0.99
		)
		if prev_value < progress_value:
			print_debug("playsfx")
	value = progress_value * 100.0
	if false_count == 0:
		GameManager.mission_completed.emit(GameManager.current_mission.id)

func get_false_status_count(data: Dictionary) -> int:
	var false_count: int = 0
	for key: Variant in data.keys():
		var v: Variant = data[key]
		if key == "status" and v is bool:
			if not v:
				false_count += 1
		elif v is Dictionary:
			false_count += get_false_status_count(v)
		elif v is Array:
			for item: Variant in v:
				if item is Dictionary:
					false_count += get_false_status_count(item)
	return false_count
