extends Control

@export var intro_lines: Array[String] = []
@export var training_room_scene: StringName = &""

@onready var panel = $Panel
@onready var intro_text: Label = $Panel/Label

func _ready() -> void:
	intro_text.visible = true
	intro_text.modulate.a = 1.0
	await intro_text.play_typing(intro_lines)
	SceneLoader.load_scene(training_room_scene)
