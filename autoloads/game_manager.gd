extends Node

signal chapter_loaded(chapter: ChapterData)
signal mission_loaded(mission: MissionData)
signal chapter_completed(id: String)
signal mission_completed(id: String)

var chapter_datas: Array[ChapterData] = [
	preload("uid://c1w13xwer3lvj"),
]
var current_chapter_id: String
var current_mission_id: String
var completed_chapter: Array[ChapterData]
var tutorial_completed: bool = false

func _ready() -> void:
	chapter_completed.connect(_on_chapter_completed)
	mission_completed.connect(_on_mission_completed)

func _on_chapter_completed(id: String) -> void:
	if current_chapter_id == "chapter0":
		tutorial_completed = true
	for chapter in chapter_datas:
		if current_chapter_id != id:
			return
		completed_chapter.append(chapter)

func _on_mission_completed(id: String) -> void:
	for chapter in completed_chapter:
		completed_chapter.append(chapter)

func load_chapter(chapter_id: String) -> void:
	for chapter in chapter_datas:
		if chapter.id != chapter_id:
			return
		current_chapter_id = chapter_id
		chapter_loaded.emit(chapter)
		load_mission(chapter.missions[0].id)

func load_mission(mission_id: String)-> void:
	for chapter in chapter_datas:
		if chapter.id != current_chapter_id:
			return
		for mission in chapter.missions:
			if mission.id != mission_id:
				return
			current_mission_id = mission_id
			mission_loaded.emit(mission)
