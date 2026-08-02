extends ProgressBar

var progress_value := 0.0

func _ready() -> void:
	NetworkManager.devices_initialized.connect(_update_progress)
	NetworkManager.device_updated.connect(_on_device_updated)
	GameManager.mission_loaded.connect(_on_mission_loaded)
	GameManager.chapter_loaded.connect(_on_chapter_loaded)
	GameManager.mission_completed.connect(_on_mission_completed_ui)
	hide()

func _on_device_updated(_device_id: String, _device_data: DeviceData) -> void:
	_update_progress()

func _on_chapter_loaded(_chapter: ChapterData) -> void:
	hide()

func _on_mission_completed_ui(_mission_id: String) -> void:
	value = 0.0
	hide()

func _on_mission_loaded(mission: MissionData) -> void:
	if mission.id == "mission0" and mission.title == "Tutorial":
		return
	show()
	_update_progress()

func _update_progress() -> void:
	if GameManager.current_mission == null:
		return
	var counts := get_status_counts(NetworkManager.mission_checking_result)
	var total : int = counts.true_count + counts.false_count
	progress_value = 1.0 if total == 0 else float(counts.true_count) / float(total)
	if value < progress_value * 100.0:
		print_debug("playsfx")
	value = progress_value * 100.0
	if counts.false_count == 0:
		var is_mission_completed: bool = GameManager.is_mission_completed(
			GameManager.current_mission.id
		)
		if not is_mission_completed and GameManager.current_mission.id != "default":
			GameManager.mission_completed.emit(GameManager.current_mission.id)

func get_status_counts(data: Dictionary) -> Dictionary:
	var result := {
		"true_count": 0,
		"false_count": 0
	}
	
	for key in data:
		var value = data[key]
		if key == "status" and value is bool:
			if value:
				result.true_count += 1
			else:
				result.false_count += 1

		elif value is Dictionary:
			var child := get_status_counts(value)
			result.true_count += child.true_count
			result.false_count += child.false_count

		elif value is Array:
			for item in value:
				if item is Dictionary:
					var child := get_status_counts(item)
					result.true_count += child.true_count
					result.false_count += child.false_count

	return result
