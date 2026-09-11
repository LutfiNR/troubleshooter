extends Control

@export var start_new_game_scene: StringName = &""
@export var office_scene: StringName = &""
@export var training_scene: StringName = &""
@export var learning_objective_scene: StringName = &""
@export var credits_scene: StringName = &""


func _ready() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_music("main_menu")


func _on_lo_button_button_up() -> void:
	SceneLoader.load_scene(learning_objective_scene)


func _on_credits_button_button_up() -> void:
	SceneLoader.load_scene(credits_scene)


func _on_new_game_button_pressed() -> void:
	GameManager.new_game()
	SceneLoader.load_scene(start_new_game_scene)


func _on_load_game_button_button_up() -> void:
	GameManager.load_game()
	if GameManager.current_chapter == null:
		return
	if GameManager.current_chapter.id == "chapter0":
		SceneLoader.load_scene(training_scene)
	else:
		SceneLoader.load_scene(office_scene)


func _on_setting_button_pressed() -> void:
	var existing := get_node_or_null("SettingsPopup")
	if existing != null:
		existing.visible = true
		if existing.get_parent() != null:
			existing.get_parent().move_child(existing, existing.get_parent().get_child_count() - 1)
		return

	var settings_scene := preload("res://ui/settings/setting.tscn").instantiate()
	settings_scene.name = "SettingsPopup"
	settings_scene.layer = 100
	add_child(settings_scene)
	if settings_scene.get_parent() != null:
		settings_scene.get_parent().move_child(
			settings_scene,
			settings_scene.get_parent().get_child_count() - 1,
		)
