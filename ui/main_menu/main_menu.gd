extends Control

@export var start_new_game_scene: StringName = &""
@export var office_scene: StringName = &""
@export var training_scene: StringName = &""
@export var learning_objective_scene: StringName = &""
@export var credtis_scene: StringName = &""


func _on_lo_button_button_up() -> void:
	SceneLoader.load_scene(learning_objective_scene)

func _on_credits_button_button_up() -> void:
	SceneLoader.load_scene(credtis_scene)

func _on_new_game_button_pressed() -> void:
	SceneLoader.load_scene(start_new_game_scene)

func _on_load_game_button_button_up() -> void:
	if GameManager.current_chapter.id == "chapter0":
		SceneLoader.load_scene(training_scene)
	else:
		SceneLoader.load_scene(office_scene)
