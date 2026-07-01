extends Node

signal mission_loaded(mission: MissionData)

var chapter_datas: Array[ChapterData]

var current_chapter: String
var current_mission: String

var data_progression: Dictionary = {
	
}

func load_mission(mission: MissionData)-> void:
	current_mission = mission.id
	mission_loaded.emit(current_mission)
