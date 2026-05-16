extends Control

@export var exploration_scene: StringName

func _on_button_pressed() -> void:
	SceneLoader.load_scene(exploration_scene)
	NetworkManager.play_mode = NetworkManager.PlayMode.EXPLORATION
