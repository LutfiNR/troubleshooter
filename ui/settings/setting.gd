extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"

@onready var volume_slider: HSlider = $Panel/NinePatchRect/GridContainer/VBoxContainer/HSlider

var master_bus_index: int
var music_bus_index: int
var shared_volume: float = 0.8


func _ready() -> void:
	layer = 100
	configure_audio_buses()
	load_settings()
	volume_slider.value_changed.connect(_on_volume_slider_changed)
	apply_shared_volume()


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

	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(shared_volume))
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(shared_volume))


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	var saved_volume := 80.0

	if err == OK:
		saved_volume = float(config.get_value("audio", "master_volume", 80.0))

	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = saved_volume
	shared_volume = saved_volume / 100.0


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("audio", "music_volume", volume_slider.value)
	config.save(SETTINGS_PATH)


func apply_shared_volume() -> void:
	var volume_value: float = clamp(volume_slider.value, 0.0, 100.0)
	var volume_db := linear_to_db(volume_value / 100.0)
	shared_volume = volume_value / 100.0

	AudioServer.set_bus_volume_db(master_bus_index, volume_db)
	AudioServer.set_bus_volume_db(music_bus_index, volume_db)
	if is_instance_valid(SoundManager):
		SoundManager.set_music_volume(volume_db)
		SoundManager.set_sfx_volume(volume_db)
	save_settings()


func _on_volume_slider_changed(_value: float) -> void:
	apply_shared_volume()


func _on_exit_button_pressed() -> void:
	_play_cancel_click_sfx()
	save_settings()
	queue_free()


func _play_cancel_click_sfx() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("cancel_button_click")
