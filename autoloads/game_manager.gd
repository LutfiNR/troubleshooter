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

var game_data := {
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

func initialize_game_data() -> void:
	game_data = {
		"current_chapter": "",
		"current_mission": "",
		"chapters": {}
	}

	for chapter in chapter_datas:
		var missions := {}

		for mission in chapter.missions:
			missions[mission.id] = {
				"status": ProgressStatus.LOCKED
			}

		game_data.chapters[chapter.id] = {
			"missions": missions
		}

	for chapter in chapter_datas:
		for mission in chapter.missions:
			if mission.required_progress_id.is_empty():
				game_data.chapters[chapter.id].missions[mission.id].status = ProgressStatus.UNLOCKED

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

	update_mission_unlocks()

	if game_data.current_chapter != "":
		load_chapter(game_data.current_chapter)

	if game_data.current_mission != "":
		load_mission(game_data.current_mission)

func new_game() -> void:
	initialize_game_data()
	current_chapter = null
	current_mission = null
	save_game()

func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	new_game()

func load_chapter(chapter_id:String) -> void:
	for chapter in chapter_datas:
		if chapter.id != chapter_id:
			continue

		current_chapter = chapter
		game_data.current_chapter = chapter.id

		chapter_loaded.emit(chapter)

		if game_data.current_mission == "":
			for mission in chapter.missions:
				if mission.id == "mission0":
					load_mission(mission.id)
					break
		return

func load_mission(mission_id:String) -> void:
	if current_chapter == null:
		return

	var state = game_data.chapters[current_chapter.id].missions[mission_id]

	if state.status == ProgressStatus.LOCKED:
		return

	for mission in current_chapter.missions:
		if mission.id != mission_id:
			continue

		current_mission = mission
		game_data.current_mission = mission.id

		if state.status == ProgressStatus.UNLOCKED:
			state.status = ProgressStatus.ON_PROGRESS

		mission_loaded.emit(mission)
		save_game()
		return

func _on_mission_completed(id:String) -> void:
	var state = game_data.chapters[current_chapter.id].missions[id]

	if state.status == ProgressStatus.COMPLETED:
		return

	state.status = ProgressStatus.COMPLETED

	update_mission_unlocks()

	if get_chapter_status(current_chapter.id) == ProgressStatus.COMPLETED:
		chapter_completed.emit(current_chapter.id)

	save_game()

func _on_chapter_completed(_id:String) -> void:
	save_game()

func update_mission_unlocks() -> void:
	for chapter in chapter_datas:
		var missions = game_data.chapters[chapter.id].missions

		for mission in chapter.missions:
			var state = missions[mission.id]

			if state.status != ProgressStatus.LOCKED:
				continue

			if mission.required_progress_id.is_empty():
				state.status = ProgressStatus.UNLOCKED
			elif is_mission_completed(mission.required_progress_id):
				state.status = ProgressStatus.UNLOCKED

func get_chapter_status(chapter_id:String) -> ProgressStatus:
	var chapter := get_chapter(chapter_id)

	if chapter == null:
		return ProgressStatus.LOCKED

	var missions = game_data.chapters[chapter_id].missions

	var completed := 0
	var on_progress := false
	var unlocked := false

	for mission in chapter.missions:
		match missions[mission.id].status:
			ProgressStatus.COMPLETED:
				completed += 1
			ProgressStatus.ON_PROGRESS:
				on_progress = true
			ProgressStatus.UNLOCKED:
				unlocked = true

	if completed == chapter.missions.size():
		return ProgressStatus.COMPLETED

	if on_progress:
		return ProgressStatus.ON_PROGRESS

	if unlocked:
		return ProgressStatus.UNLOCKED

	return ProgressStatus.LOCKED

func get_mission_status(chapter_id:String, mission_id:String) -> ProgressStatus:
	return game_data.chapters[chapter_id].missions[mission_id].status

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
