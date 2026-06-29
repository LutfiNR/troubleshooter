extends Control

@export var start_scene: StringName = &""
@export var learning_objective_scene: StringName = &""
@export var settings_scene: StringName = &""
@export var credtis_scene: StringName = &""


func _on_start_button_button_up() -> void:
	SceneLoader.load_scene(start_scene)


func _on_lo_button_button_up() -> void:
	SceneLoader.load_scene(learning_objective_scene)


func _on_setting_button_button_up() -> void:
	SceneLoader.load_scene(settings_scene)


func _on_credits_button_button_up() -> void:
	SceneLoader.load_scene(credtis_scene)
