extends Panel

@onready var mission_detail_rtl: RichTextLabel = $MissionDetail

func _ready() -> void:
	GameManager.mission_loaded.connect(_on_mission_loaded)
	GameManager.chapter_loaded.connect(_on_chapter_loaded)
	GameManager.mission_completed.connect(_on_mission_completed_ui)
	hide()

func _on_chapter_loaded(_chapter: ChapterData) -> void:
	hide()

func _on_mission_completed_ui(_mission_id: String) -> void:
	hide()

func _on_mission_loaded(mission: MissionData) -> void:
	if mission.id == "mission0" and mission.title == "Tutorial":
		return
	mission_detail_rtl.text = mission.guide
	show()
