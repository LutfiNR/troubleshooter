extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"

@onready var master_slider: HSlider = $Panel/NinePatchRect/GridContainer/VBoxContainer/HSlider
@onready var music_slider: HSlider = $Panel/NinePatchRect/GridContainer/VBoxContainer2/HSlider

var master_bus_index: int
var music_bus_index: int


func _ready() -> void:
	layer = 100
	configure_audio_buses()
	load_settings()
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	apply_volume_settings()


func configure_audio_buses() -> void:
	master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index == -1:
		AudioServer.add_bus()
		master_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(master_bus_index, "Master")

	music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		AudioServer.add_bus()
		music_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_index, "Music")

	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(0.8))
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(0.8))


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	var saved_master := 80.0
	var saved_music := 80.0

	if err == OK:
		saved_master = float(config.get_value("audio", "master_volume", 80.0))
		saved_music = float(config.get_value("audio", "music_volume", 80.0))

	master_slider.min_value = 0.0
	master_slider.max_value = 100.0
	master_slider.step = 1.0
	master_slider.value = saved_master

	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	music_slider.value = saved_music


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.save(SETTINGS_PATH)


func apply_volume_settings() -> void:
	var master_value: float = clamp(master_slider.value, 0.0, 100.0)
	var music_value: float = clamp(music_slider.value, 0.0, 100.0)

	var master_db := linear_to_db(master_value / 100.0)
	var music_db := linear_to_db(music_value / 100.0)

	AudioServer.set_bus_volume_db(master_bus_index, master_db)
	AudioServer.set_bus_volume_db(music_bus_index, music_db)
	if is_instance_valid(SoundManager):
		SoundManager.set_music_volume(music_db)
		save_settings()


func _on_master_slider_changed(_value: float) -> void:
	apply_volume_settings()


func _on_music_slider_changed(_value: float) -> void:
	apply_volume_settings()


func _on_exit_button_pressed() -> void:
	save_settings()
	queue_free()
