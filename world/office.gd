extends Node2D

const CHAPTER_ID := "chapter1"

func _ready() -> void:
	if GameManager.current_chapter == null \
	or GameManager.current_chapter.id != CHAPTER_ID:
		GameManager.load_chapter(CHAPTER_ID)
