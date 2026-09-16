extends CanvasLayer

@onready var volume_slider: HSlider = $Panel/NinePatchRect/GridContainer/VBoxContainer/HSlider
@onready var surrender_button: Button = $Panel/NinePatchRect/GridContainer/HBoxContainer/SurrenderButton
@onready var main_menu_button: Button = $Panel/NinePatchRect/GridContainer/HBoxContainer/MainMenuButton

var in_game: bool

func _ready() -> void:
	layer = 100

	# Configure slider based on the SoundManager's loaded config
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0

	# Safely get the value if SoundManager exists
	if is_instance_valid(SoundManager):
		volume_slider.value = SoundManager.global_volume

	volume_slider.value_changed.connect(_on_volume_slider_changed)
	if not in_game:
		return
	main_menu_button.show()
	if not GameManager.current_mission:
		return
	if GameManager.current_mission.id == "mission0" or GameManager.current_mission.id == "mission1":
		surrender_button.hide()
		return
	surrender_button.show()
	main_menu_button.hide()

func _on_volume_slider_changed(value: float) -> void:
	if is_instance_valid(SoundManager):
		# SoundManager handles DB conversion and saving automatically
		SoundManager.apply_volume(value)

func _on_exit_button_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("cancel_button_click")
		# Ensure it saves one final time on exit (optional, as the slider already saves)
		SoundManager.save_settings(volume_slider.value)
	get_tree().paused = false
	queue_free()

func _on_surrender_button_pressed() -> void:
	get_tree().paused = false
	GameManager.mission_failed.emit(GameManager.current_mission.id)


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	SceneLoader.load_scene("uid://ndgyeswawkpj")
