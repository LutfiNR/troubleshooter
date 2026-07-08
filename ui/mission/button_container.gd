extends HBoxContainer

@export var roadmap_popup_scene: PackedScene
@export var mission_popup_scene: PackedScene
@export var check_popup_scene: PackedScene

@onready var popup_container: VBoxContainer = $"../PopupContainer"

var check_open_limit: int = 0
var check_open_count: int = 0
var current_popup_scene: PackedScene = null

func _ready() -> void:
	GameManager.mission_loaded.connect(_on_mission_loaded)

func _on_mission_loaded(mission: MissionData) -> void:
	check_open_limit = mission.check_progress_limit
	check_open_count = 0
	update_ui()

func show_popup(scene: PackedScene) -> void:
	hide_popup()
	if scene:
		popup_container.add_child(scene.instantiate())
		current_popup_scene = scene
		popup_container.show()

func hide_popup() -> void:
	for child in popup_container.get_children():
		child.queue_free()
	current_popup_scene = null
	popup_container.hide()

func has_same_popup(scene: PackedScene) -> bool:
	return current_popup_scene == scene

func _on_roadmap_button_pressed() -> void:
	if has_same_popup(roadmap_popup_scene):
		hide_popup()
	else:
		show_popup(roadmap_popup_scene)
		if not GameManager.tutorial_completed.has("roadmap"):
			DialogueManager.show_dialogue_balloon(load("uid://btbt3t63k53gq"), "roadmap")
			GameManager.tutorial_completed.append("roadmap")

func _on_mission_button_pressed() -> void:
	if has_same_popup(mission_popup_scene):
		hide_popup()
	else:
		show_popup(mission_popup_scene)
		if not GameManager.tutorial_completed.has("mission"):
			DialogueManager.show_dialogue_balloon(load("uid://btbt3t63k53gq"), "mission")
			GameManager.tutorial_completed.append("mission")
func _on_check_progress_button_pressed() -> void:
	if has_same_popup(check_popup_scene):
		hide_popup()
		return
	if check_open_count >= check_open_limit:
		return
	check_open_count += 1
	update_ui()
	show_popup(check_popup_scene)
	if not GameManager.tutorial_completed.has("check"):
		DialogueManager.show_dialogue_balloon(load("uid://btbt3t63k53gq"), "check")
		GameManager.tutorial_completed.append("check")
	
func update_ui() -> void:
	$CheckProgressButton/Label.text = str(check_open_count) + "/" + str(check_open_limit)
