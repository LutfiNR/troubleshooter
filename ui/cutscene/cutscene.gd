extends Control

@export var lose_intro_lines: Array[String] = []
@export var win_intro_lines: Array[String] = []
@export var next_scene: StringName = &""

@onready var panel = $Panel
@onready var intro_text: Label = $Panel/Label
@onready var title_label: Label = $Panel/TitleLabel

func _ready() -> void:
	GameManager.mission_completed.connect(_on_mission_completed)
	intro_text.visible = true
	intro_text.modulate.a = 1.0
	await intro_text.play_typing(lose_intro_lines)
	SceneLoader.load_scene(next_scene)

func _on_mission_completed(_mission_id: String)-> void:
	intro_text.visible = true
	intro_text.modulate.a = 1.0
	await intro_text.play_typing(win_intro_lines)
	SceneLoader.load_scene(next_scene)
