extends CanvasLayer

signal loading_screen_ready

@export var panel_animation: AnimationPlayer
@export var logo_animation: AnimationPlayer
@onready var logo: TextureRect = $TextureRect
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready()->void:
	await panel_animation.animation_finished
	logo.show()
	progress_bar.show()
	logo_animation.play("rotating")
	loading_screen_ready.emit()

func _on_progress_changed(new_value: float)-> void:
	if new_value != 0.0:
		progress_bar.value = new_value * 100

func _on_load_finished()-> void:
	logo_animation.stop()
	logo.hide()
	progress_bar.hide()
	panel_animation.play_backwards("slide_in")
	await panel_animation.animation_finished
	queue_free()
