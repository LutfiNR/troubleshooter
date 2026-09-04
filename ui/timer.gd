extends Label

var mission_time: float = -1.0


func _ready() -> void:
	GameManager.mission_loaded.connect(_on_mission_loaded)
	if GameManager.current_mission != null:
		_on_mission_loaded(GameManager.current_mission)


func _process(delta: float) -> void:
	if mission_time == -1:
		return
	mission_time -= delta
	text = _format_time(mission_time)
	if mission_time <= 0:
		SceneLoader.load_scene("uid://huymfpmo6da0")


func _on_mission_loaded(mission: MissionData) -> void:
	mission_time = mission.time


func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = total_seconds / 60
	var secs = total_seconds % 60
	return "%02d : %02d" % [minutes, secs]
