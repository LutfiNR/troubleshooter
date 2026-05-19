extends Control

@export var exploration_scene: StringName

#func _ready() -> void:
	#print(PlaceableItem.Type.keys()[PlaceableItem.Type.COMPUTER].to_lower())
	
func _on_button_pressed() -> void:
	SceneLoader.load_scene(exploration_scene)
	GameManager.play_mode = GameManager.PlayMode.EXPLORATION
