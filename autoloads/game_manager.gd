extends Node

signal chapter_loaded(chapter: ChapterData)
signal mission_loaded(mission: MissionData)
signal chapter_completed(id: String)
signal mission_completed(id: String)

var chapter_datas: Array[ChapterData] = [
	preload("uid://c1w13xwer3lvj"),
]

var game_data: Dictionary = {
	"completed_chapters": {
		
	}
}

var current_chapter: ChapterData
var current_mission: MissionData
var completed_current_chapter_missions: Array[String] = []
var tutorial_completed: Array[String]

func _ready() -> void:
	chapter_completed.connect(_on_chapter_completed)
	mission_completed.connect(_on_mission_completed)

func _on_chapter_completed(id: String) -> void:
	for chapter in chapter_datas:
		if chapter.id == id:
			if !game_data.completed_chapters.has(chapter.id):
				game_data.completed_chapters[chapter.id] = { 
					"completed_missions": completed_current_chapter_missions
					}
			return

func _on_mission_completed(id: String) -> void:
	for mission in current_chapter.missions:
		if mission.id == id:
			if !completed_current_chapter_missions.has(mission.id):
				completed_current_chapter_missions.append(mission.id)
			if completed_current_chapter_missions.size() == current_chapter.missions.size():
				chapter_completed.emit(current_chapter.id)
			return

func load_chapter(chapter_id: String) -> void:
	for chapter in chapter_datas:
		if chapter.id == chapter_id:
			current_chapter = chapter
			chapter_loaded.emit(chapter)
			if chapter.id == "chapter0":
				load_mission(chapter.missions[0].id)
			return

func load_mission(mission_id: String) -> void:
	if current_chapter == null:
		return
	for mission in current_chapter.missions:
		if mission.id == mission_id:
			current_mission = mission
			mission_loaded.emit(mission)
			return
