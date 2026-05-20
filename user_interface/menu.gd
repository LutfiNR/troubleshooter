extends Control

@export var exploration_scene: StringName
@export var office_scene: StringName

#func _ready() -> void:
	#print(PlaceableItem.Type.keys()[PlaceableItem.Type.COMPUTER].to_lower())
	
func _on_button_pressed() -> void:
	SceneLoader.load_scene(exploration_scene)
	GameManager.play_mode = GameManager.PlayMode.EXPLORATION


func _on_button_2_pressed() -> void:
	SceneLoader.load_scene(office_scene)
	GameManager.play_mode = GameManager.PlayMode.MISSION
