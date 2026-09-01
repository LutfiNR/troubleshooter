extends Panel

@onready var mission_detail_rtl: RichTextLabel = $MissionDetail

func _ready() -> void:
	if not GameManager.current_mission:
		mission_detail_rtl.text = GameManager.current_chapter.guide
		return
	mission_detail_rtl.text = GameManager.current_mission.guide
