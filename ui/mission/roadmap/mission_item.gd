extends Button

@export var mission_icon_texture: Dictionary[StringName, Texture2D] = {
	"locked": null,
	"unlocked": null,
	"on_progress": null,
	"completed": null,
}

@onready var mission_icon: TextureRect = $Icon
@onready var title: Label = $Title

var chapter_id: String
var mission_id: String

const STATUS_ICON := {
	GameManager.ProgressStatus.LOCKED: "locked",
	GameManager.ProgressStatus.UNLOCKED: "unlocked",
	GameManager.ProgressStatus.ON_PROGRESS: "on_progress",
	GameManager.ProgressStatus.COMPLETED: "completed",
}


func setup(chapter: ChapterData, mission: MissionData) -> void:
	GameManager.mission_loaded.connect(_on_mission_loaded)
	GameManager.mission_completed.connect(_on_mission_completed)
	chapter_id = chapter.id
	mission_id = mission.id
	title.text = mission.title
	update_ui()


func update_ui() -> void:
	var status: GameManager.ProgressStatus = GameManager.get_game_data_mission_status(
		chapter_id,
		mission_id,
	)
	mission_icon.texture = mission_icon_texture.get(STATUS_ICON[status], null)
	disabled = status != GameManager.ProgressStatus.UNLOCKED


func _on_mission_loaded(_mission_data: MissionData) -> void:
	update_ui()


func _on_mission_completed(_mission_id: String) -> void:
	update_ui()


func _on_pressed() -> void:
	GameManager.load_mission(mission_id)
