extends Control


func _ready() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_music("learning_objectif")


func _on_exit_button_pressed() -> void:
	SceneLoader.load_scene("uid://ndgyeswawkpj")


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
