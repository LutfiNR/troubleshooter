extends Node2D

const CHAPTER_ID := "chapter1"

@export var mission_completed_dialogue: DialogueResource

var completed_mission_id := ""


func _ready() -> void:
	GameManager.mission_completed.connect(_on_mission_completed)
	if mission_completed_dialogue == null:
		mission_completed_dialogue = load("res://dialogue/office_mission_completed.dialogue") as DialogueResource
	if GameManager.current_chapter == null \
			or GameManager.current_chapter.id != CHAPTER_ID:
		GameManager.load_chapter(CHAPTER_ID)


func _on_mission_completed(mission_id: String) -> void:
	if completed_mission_id == mission_id:
		return
	completed_mission_id = mission_id
	if mission_completed_dialogue:
		DialogueManager.show_dialogue_balloon(mission_completed_dialogue, "mission_completed")
