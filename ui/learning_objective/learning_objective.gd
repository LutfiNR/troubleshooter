extends Control


func _ready() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_music("learning_objectif")


func _on_exit_button_pressed() -> void:
	_play_cancel_click_sfx()
	SceneLoader.load_scene("uid://ndgyeswawkpj")


func _on_setting_button_pressed() -> void:
	_play_click_sfx()
	get_tree().paused = true
	var existing := get_node_or_null("PauseMenu")
	if existing != null:
		existing.visible = true
		if existing.get_parent() != null:
			existing.get_parent().move_child(existing, existing.get_parent().get_child_count() - 1)
		return

	var pause_scene := preload("res://ui/pause_menu/pause_menu.tscn").instantiate()
	pause_scene.name = "PauseMenu"
	pause_scene.layer = 100
	pause_scene.in_game = false
	add_child(pause_scene)
	if pause_scene.get_parent() != null:
		pause_scene.get_parent().move_child(
			pause_scene,
			pause_scene.get_parent().get_child_count() - 1,
		)


func _play_cancel_click_sfx() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("cancel_button_click")


func _play_click_sfx() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("button_click")
