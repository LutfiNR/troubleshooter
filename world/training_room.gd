extends Node2D

const CHAPTER_ID: String = "chapter0"
const TUTORIAL_MISSION_ID: String = "mission0"

func _ready() -> void:
	if GameManager.current_chapter == null \
	or GameManager.current_chapter.id != CHAPTER_ID:
		GameManager.load_chapter(CHAPTER_ID)

	if GameManager.current_mission == null:
		GameManager.load_mission(TUTORIAL_MISSION_ID)
