extends Node2D

@export var tutorial_dialog: DialogueResource
func _ready() -> void:
	if not GameManager.tutorial_completed.has("movement"):
		DialogueManager.show_dialogue_balloon(tutorial_dialog, "movement")
		await DialogueManager.dialogue_ended
		GameManager.tutorial_completed.append("movement")

func _on_interact_trigger_body_entered(body: Node2D) -> void:
	if not GameManager.tutorial_completed.has("interact") and GameManager.tutorial_completed.has("movement"):
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "interact")
			await DialogueManager.dialogue_ended
			GameManager.tutorial_completed.append("interact")

func _on_interact_trigger_body_exited(body: Node2D) -> void:
	if not GameManager.tutorial_completed.has("after_interact") and GameManager.tutorial_completed.has("interact"):
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "after_interact")
			await DialogueManager.dialogue_ended
			GameManager.tutorial_completed.append("after_interact")
			
func _on_device_trigger_body_entered(body: Node2D) -> void:
	if not GameManager.tutorial_completed.has("device") and GameManager.tutorial_completed.has("after_interact"):
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(tutorial_dialog, "device")
			await DialogueManager.dialogue_ended
			GameManager.tutorial_completed.append("device")
