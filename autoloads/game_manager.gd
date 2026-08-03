extends Node

enum ProgressStatus { LOCKED, UNLOCKED, ON_PROGRESS, COMPLETED }

signal chapter_loaded(chapter: ChapterData)
signal mission_loaded(mission: MissionData)
signal chapter_completed(id: String)
signal mission_completed(id: String)

const SAVE_PATH := "user://save_game.dat"

var chapter_datas: Array[ChapterData] = [
	preload("uid://c1w13xwer3lvj"),
	preload("uid://c6v81yrcson83"),
]

var game_data : Dictionary = {
	"current_chapter": "",
	"current_mission": "",
	"chapters": {}
}

var current_chapter: ChapterData
var tutorial_completed: Array[String]
var current_mission: MissionData

func _ready() -> void:
	chapter_completed.connect(_on_chapter_completed)
	mission_completed.connect(_on_mission_completed)

	if FileAccess.file_exists(SAVE_PATH):
		load_game()
	else:
		new_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_var(game_data)
	file.close()

func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		new_game()
		return
	game_data = file.get_var()
	file.close()
	if game_data.current_chapter != "":
		load_chapter(game_data.current_chapter)
	if game_data.current_mission != "":
		load_mission(game_data.current_mission)

func new_game() -> void:
	initialize_game_data()
	save_game()

func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	new_game()

func initialize_game_data() -> void:
	reset_game_data()
	initialize_progress_data()

func reset_game_data()->void:
	game_data = {
		"current_chapter": "",
		"current_mission": "",
		"chapters": {}
	}
	current_chapter = null
	current_mission = null

func initialize_progress_data()-> void:
	for chapter in chapter_datas:
		var missions := {}
		for mission in chapter.missions:
			missions[mission.id] = {
				"status": ProgressStatus.LOCKED
			}
		game_data.chapters[chapter.id] = {
			"status" : ProgressStatus.LOCKED,
			"missions": missions
		}
	for chapter in chapter_datas:
		if chapter.required_progress_id.is_empty():
			game_data.chapters[chapter.id].status = ProgressStatus.UNLOCKED
		for mission in chapter.missions:
			if mission.required_progress_id.is_empty():
				game_data.chapters[chapter.id].missions[mission.id].status = ProgressStatus.UNLOCKED

func load_chapter(chapter_id:String) -> void:
	if get_game_data_chapter_status(chapter_id) == ProgressStatus.LOCKED:
		return

	for chapter in chapter_datas:
		if chapter.id != chapter_id:
			continue
		current_chapter = chapter
		game_data.current_chapter = chapter.id
		if get_game_data_chapter_status(chapter_id) == ProgressStatus.UNLOCKED:
			set_game_data_chapter_status(chapter_id, ProgressStatus.ON_PROGRESS)
		chapter_loaded.emit(chapter)
		save_game()
		NetworkManager.load_default_configuration(current_chapter.default_configs, current_chapter.default_cables)
		return

func load_mission(mission_id:String) -> void:
	if current_chapter == null:
		return
	if is_mission_locked(mission_id):
		return
	for mission in current_chapter.missions:
		if mission.id != mission_id:
			continue
		current_mission = mission
		game_data.current_mission = mission.id
		if get_game_data_mission_status(current_chapter.id, mission_id) == ProgressStatus.UNLOCKED:
			set_game_data_mission_status(current_chapter.id, mission_id, ProgressStatus.ON_PROGRESS)
			print_debug(mission_id, " loaded with status ", get_game_data_mission_status(current_chapter.id, mission_id))
			print_debug(game_data)
		mission_loaded.emit(mission)
		save_game()
		return

func _on_mission_completed(mission_id:String) -> void:
	if is_mission_completed(mission_id):
		return
	set_game_data_mission_status(current_chapter.id, mission_id, ProgressStatus.COMPLETED)
	unlock_new_mission()
	var all_missions_completed := true
	for game_data_mission in game_data.chapters[current_chapter.id].missions.values():
		if game_data_mission.status != ProgressStatus.COMPLETED:
			all_missions_completed = false
			break
	if all_missions_completed:
		chapter_completed.emit(current_chapter.id)
	current_mission = null
	game_data.current_mission = ""
	save_game()
	NetworkManager.load_default_configuration(current_chapter.default_configs, current_chapter.default_cables)

func _on_chapter_completed(chapter_id:String) -> void:
	if is_chapter_completed(chapter_id):
		return
	set_game_data_chapter_status(chapter_id, ProgressStatus.COMPLETED)
	unlock_new_chapter()
	save_game()

func unlock_new_mission() -> void:
	for chapter_data in chapter_datas:
		for mission_data in chapter_data.missions:
			var status := get_game_data_mission_status(chapter_data.id, mission_data.id)
			if status != ProgressStatus.LOCKED:
				continue
			if mission_data.required_progress_id.is_empty():
				set_game_data_mission_status(chapter_data.id, mission_data.id, ProgressStatus.UNLOCKED)
				print_debug(game_data)
			elif is_mission_completed(mission_data.required_progress_id) \
					or is_chapter_completed(mission_data.required_progress_id):
				set_game_data_mission_status(chapter_data.id, mission_data.id, ProgressStatus.UNLOCKED)
				print_debug(game_data)

func unlock_new_chapter() -> void:
	for chapter_data in chapter_datas:
		var status := get_game_data_chapter_status(chapter_data.id)
		if status != ProgressStatus.LOCKED:
			continue
		if chapter_data.required_progress_id.is_empty():
			set_game_data_chapter_status(chapter_data.id, ProgressStatus.UNLOCKED)
		elif is_chapter_completed(chapter_data.required_progress_id):
			set_game_data_chapter_status(chapter_data.id, ProgressStatus.UNLOCKED)

func set_game_data_chapter_status(chapter_id: String, status:ProgressStatus)-> void:
	game_data.chapters[chapter_id].status = status

func set_game_data_mission_status(chapter_id:String, mission_id: String, status:ProgressStatus)-> void:
	game_data.chapters[chapter_id].missions[mission_id].status = status

func get_game_data_chapter_status(chapter_id:String) -> ProgressStatus:
	return game_data.chapters[chapter_id].status

func get_game_data_mission_status(chapter_id:String, mission_id:String) -> ProgressStatus:
	return game_data.chapters[chapter_id].missions[mission_id].status

func is_chapter_locked(chapter_id: String)-> bool:
	if game_data.chapters.has(chapter_id):
		return game_data.chapters[chapter_id].status == ProgressStatus.LOCKED
	return false

func is_mission_locked(mission_id: String)-> bool:
	for chapter in game_data.chapters.values():
		if game_data.chapters.has(mission_id):
			return chapter.missions[mission_id].status == ProgressStatus.LOCKED
	return false

func is_chapter_completed(chapter_id: String) -> bool:
	if game_data.chapters.has(chapter_id):
		return game_data.chapters[chapter_id].status == ProgressStatus.COMPLETED
	return false

func is_mission_completed(mission_id:String) -> bool:
	for chapter in game_data.chapters.values():
		if chapter.missions.has(mission_id):
			return chapter.missions[mission_id].status == ProgressStatus.COMPLETED
	return false

func get_chapter(chapter_id:String) -> ChapterData:
	for chapter in chapter_datas:
		if chapter.id == chapter_id:
			return chapter
	return null

func get_mission(mission_id:String) -> MissionData:
	for chapter in chapter_datas:
		for mission in chapter.missions:
			if mission.id == mission_id:
				return mission
	return null
