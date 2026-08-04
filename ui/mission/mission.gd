extends Panel

@onready var mission_detail_rtl: RichTextLabel = $MissionDetail

func _ready() -> void:
	mission_detail_rtl.text = GameManager.current_mission.guide
