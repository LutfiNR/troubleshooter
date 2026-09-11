extends CharacterBody2D

# References
@onready var movement: PlayerMovementComponent = $PlayerMovementComponent
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
#@onready var ui: CanvasLayer = $CanvasLayer

@export var camera_limit: Dictionary[String, int]


func _ready():
	# Connect the signals from the component
	movement.started_moving.connect(_on_movement_started)
	movement.stopped.connect(_on_movement_stopped)
	_on_tilemap_changed()


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


func _on_setting_button_pressed() -> void:
	_play_click_sfx()
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


func _play_click_sfx() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("button_click")
