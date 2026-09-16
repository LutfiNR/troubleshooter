extends Node2D

@export var tutorial_dialog: DialogueResource

var player_inside_interact := false
var player_inside_device := false


func _ready() -> void:
	GameManager.chapter_completed.connect(_on_chapter_completed)

	_start_tutorials()


func _start_tutorials() -> void:
	# =========================
	# MOVEMENT
	# =========================
	if not GameManager.game_data.tutorial_completed.has("movement"):
		DialogueManager.show_dialogue_balloon(
			tutorial_dialog,
			"movement"
		)

		await DialogueManager.dialogue_ended

		GameManager.tutorial_completed.emit("movement")

	# Check interact area after movement finishes.
	_try_interact_tutorial()

	# Check device area as well.
	# This handles cases where the player somehow
	# entered the device area before previous tutorials finished.
	_try_device_tutorial()


# =========================================================
# INTERACT AREA
# =========================================================

func _on_interact_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Remember that the player is currently inside.
	player_inside_interact = true

	_try_interact_tutorial()


func _on_interact_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Player is no longer inside the interact area.
	player_inside_interact = false

	_try_after_interact_tutorial()


func _try_interact_tutorial() -> void:
	# Player must be inside the interact area.
	if not player_inside_interact:
		return

	# Don't show it again.
	if GameManager.game_data.tutorial_completed.has("interact"):
		return

	# Movement must be completed first.
	if not GameManager.game_data.tutorial_completed.has("movement"):
		return

	DialogueManager.show_dialogue_balloon(
		tutorial_dialog,
		"interact"
	)

	await DialogueManager.dialogue_ended

	GameManager.tutorial_completed.emit("interact")


# =========================================================
# AFTER INTERACT
# =========================================================

func _try_after_interact_tutorial() -> void:
	# Don't show it again.
	if GameManager.game_data.tutorial_completed.has("after_interact"):
		return

	# Interact must be completed first.
	if not GameManager.game_data.tutorial_completed.has("interact"):
		return

	DialogueManager.show_dialogue_balloon(
		tutorial_dialog,
		"after_interact"
	)

	await DialogueManager.dialogue_ended

	GameManager.tutorial_completed.emit("after_interact")

	# IMPORTANT:
	# The player may already be inside the device area
	# while after_interact was being displayed.
	_try_device_tutorial()


# =========================================================
# DEVICE AREA
# =========================================================

func _on_device_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Remember that the player is currently inside.
	player_inside_device = true

	_try_device_tutorial()


func _on_device_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Player is no longer inside the device area.
	player_inside_device = false


func _try_device_tutorial() -> void:
	# Player must be inside the device area.
	if not player_inside_device:
		return

	# Don't show it again.
	if GameManager.game_data.tutorial_completed.has("device"):
		return

	# after_interact must be completed first.
	if not GameManager.game_data.tutorial_completed.has("after_interact"):
		return

	DialogueManager.show_dialogue_balloon(
		tutorial_dialog,
		"device"
	)

	await DialogueManager.dialogue_ended

	GameManager.tutorial_completed.emit("device")


# =========================================================
# CHAPTER COMPLETED
# =========================================================

func _on_chapter_completed(chapter_id: String) -> void:
	if chapter_id == "chapter0":
		DialogueManager.show_dialogue_balloon(
			tutorial_dialog,
			"chapter0_completed"
		)
