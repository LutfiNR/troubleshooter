extends CanvasLayer

@onready var volume_slider: HSlider = $Panel/NinePatchRect/GridContainer/VBoxContainer/HSlider

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

func _on_volume_slider_changed(value: float) -> void:
	if is_instance_valid(SoundManager):
		# SoundManager handles DB conversion and saving automatically
		SoundManager.apply_volume(value)

func _on_exit_button_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("cancel_button_click")
		# Ensure it saves one final time on exit (optional, as the slider already saves)
		SoundManager.save_settings(volume_slider.value)
	
	queue_free()
