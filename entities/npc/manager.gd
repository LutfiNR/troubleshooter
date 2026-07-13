extends CharacterBody2D

@export var dialogue: DialogueResource
@onready var animation_player: AnimationPlayer = $Panel/TalkIndicator/AnimationPlayer

var has_introducing: bool = false
var tutorial_completed: bool = false
var player_in_range: bool = false

func _ready() -> void:
	GameManager.chapter_completed.connect(_on_chapter_completed)

func _on_chapter_completed(id: String)-> void:
	if id == "chapter0":
		tutorial_completed = true
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		animation_player.play("talk")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		animation_player.play_backwards("talk")

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_in_range:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			DialogueManager.show_dialogue_balloon(dialogue, "start" ,[self])
