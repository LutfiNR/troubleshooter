extends Label

var mission_time: float

func _ready() -> void:
	GameManager.mission_loaded.connect(_on_mission_loaded)
	
func _process(delta: float) -> void:
	mission_time -= delta
	text = _format_time(mission_time)

func _on_mission_loaded(mission: MissionData)-> void:
	mission_time = mission.time

func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = total_seconds / 60
	var secs = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]
