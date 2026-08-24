extends Node2D

@export var tutorial_dialog: DialogueResource


func _ready() -> void:
	GameManager.chapter_completed.connect(_on_chapter_completed)
	if not GameManager.game_data.tutorial_completed.has("movement"):
		DialogueManager.show_dialogue_balloon(tutorial_dialog, "movement")
		await DialogueManager.dialogue_ended
		GameManager.tutorial_completed.emit("movement")


func _on_interact_trigger_body_entered(body: Node2D) -> void:
	if (
		not GameManager.game_data.tutorial_completed.has("interact")
		and GameManager.game_data.tutorial_completed.has("movement")
	):
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "interact")
			await DialogueManager.dialogue_ended
			GameManager.tutorial_completed.emit("interact")


func _on_interact_trigger_body_exited(body: Node2D) -> void:
	if (
		not GameManager.game_data.tutorial_completed.has("after_interact")
		and GameManager.game_data.tutorial_completed.has("interact")
	):
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "after_interact")
			await DialogueManager.dialogue_ended
			GameManager.tutorial_completed.emit("after_interact")


func _on_device_trigger_body_entered(body: Node2D) -> void:
	if (
		not GameManager.game_data.tutorial_completed.has("device")
		and GameManager.game_data.tutorial_completed.has("after_interact")
	):
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "device")
			await DialogueManager.dialogue_ended
			GameManager.tutorial_completed.emit("device")
			await get_tree().create_timer(1).timeout
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "tutorial_completed")
			await DialogueManager.dialogue_ended
			GameManager.mission_completed.emit("mission0")


func _on_chapter_completed(chapter_id: String) -> void:
	if chapter_id == "chapter0":
		DialogueManager.show_dialogue_balloon(tutorial_dialog, "chapter0_completed")
