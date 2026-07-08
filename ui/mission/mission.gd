extends Panel

@onready var mission_detail_rtl: RichTextLabel = $MissionDetail

func _ready() -> void:
	if GameManager.current_mission:
		update_ui(GameManager.current_mission)
	GameManager.mission_loaded.connect(update_ui)

func update_ui(mission: MissionData) -> void:
	mission_detail_rtl.text = mission.guide
