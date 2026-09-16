extends CharacterBody2D

# References
@onready var movement: PlayerMovementComponent = $PlayerMovementComponent
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var tutorial_arrow: TextureRect = $CanvasLayer/Control/TutorialArrow
@onready var tutorial_arrow_2: TextureRect = $CanvasLayer/Control/TutorialArrow2

@export var tutorial_dialog: DialogueResource
@export var camera_limit: Dictionary[String, int]


func _ready():
	# Connect the signals from the component
	GameManager.tutorial_completed.connect(_on_tutorial_completed)
	movement.started_moving.connect(_on_movement_started)
	movement.stopped.connect(_on_movement_stopped)
	_on_tilemap_changed()

func _on_tutorial_completed(tutorial_id)->void:
	if tutorial_id == "device":
		tutorial_arrow.show()
	if tutorial_id == "roadmap":
		tutorial_arrow.hide()
		tutorial_arrow_2.show()
	if tutorial_id == "mission":
		tutorial_arrow_2.hide()
		tutorial_arrow_2.get_parent().queue_free()
		await get_tree().create_timer(1).timeout
		DialogueManager.show_dialogue_balloon(tutorial_dialog, "tutorial_completed")
		await DialogueManager.dialogue_ended
		GameManager.mission_completed.emit("mission0")


# --- Signal Callbacks ---
func _on_tilemap_changed():
	camera.change_limit_camera(camera_limit)


func _on_movement_started(direction: Vector2):
	if direction.x < 0:
		anim_player.play("walk_left")
	elif direction.x > 0:
		anim_player.play("walk_right")
	elif direction.y > 0:
		anim_player.play("walk_down")
	elif direction.y < 0:
		anim_player.play("walk_up")


func _on_movement_stopped(last_direction: Vector2):
	anim_player.stop()
	if last_direction.x < 0:
		sprite.frame = 4
	if last_direction.x > 0:
		sprite.frame = 8
	elif last_direction.y > 0:
		sprite.frame = 0
	elif last_direction.y < 0:
		sprite.frame = 12


func _play_click_sfx() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("button_click")


func _on_pause_button_pressed() -> void:
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
	pause_scene.in_game = true
	add_child(pause_scene)
	if pause_scene.get_parent() != null:
		pause_scene.get_parent().move_child(
			pause_scene,
			pause_scene.get_parent().get_child_count() - 1,
		)
