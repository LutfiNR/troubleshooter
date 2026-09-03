extends ProgressBar

var progress_value := 0.0


func _ready() -> void:
	NetworkManager.devices_initialized.connect(_update_progress)
	NetworkManager.device_updated.connect(_on_device_updated)
	GameManager.mission_loaded.connect(_on_mission_loaded)
	GameManager.chapter_loaded.connect(_on_chapter_loaded)
	GameManager.mission_completed.connect(_on_mission_completed_ui)
	if GameManager.current_mission != null:
		_on_mission_loaded(GameManager.current_mission)
	else:
		reset_value()


func _on_device_updated(_device_id: String, _device_data: DeviceData) -> void:
	_update_progress()


func _on_chapter_loaded(_chapter: ChapterData) -> void:
	reset_value()


func _on_mission_completed_ui(_mission_id: String) -> void:
	reset_value()


func _on_mission_loaded(mission: MissionData) -> void:
	if mission.id == "mission0" and mission.title == "Tutorial":
		reset_value()
		return
	show_percentage = true
	_update_progress()


func reset_value() -> void:
	show_percentage = false
	value = 0.0


func _update_progress() -> void:
	if GameManager.current_mission == null:
		return
	var counts := get_status_counts(NetworkManager.mission_checking_result)
	var total: int = counts.true_count + counts.false_count
	if counts.false_count == 0:
		progress_value = 1.0
	else:
		progress_value = floor(float(counts.true_count) / float(total) * 100.0) / 100.0
	value = progress_value * 100.0
	print_debug("False count: %d, Progress value: %.2f" % [counts.false_count, progress_value])
	if counts.false_count == 0:
		var is_mission_completed: bool = GameManager.is_mission_completed(
			GameManager.current_mission.id
		)
		if not is_mission_completed and GameManager.current_mission.title != "Tutorial":
			GameManager.mission_completed.emit(GameManager.current_mission.id)


func get_status_counts(data: Dictionary) -> Dictionary:
	var result := { "true_count": 0, "false_count": 0 }

	for key in data:
		var status_value = data[key]
		if key == "status" and status_value is bool:
			if status_value:
				result.true_count += 1
			else:
				result.false_count += 1

		elif status_value is Dictionary:
			var child := get_status_counts(status_value)
			result.true_count += child.true_count
			result.false_count += child.false_count

		elif status_value is Array:
			for item in status_value:
				if item is Dictionary:
					var child := get_status_counts(item)
					result.true_count += child.true_count
					result.false_count += child.false_count

	return result
