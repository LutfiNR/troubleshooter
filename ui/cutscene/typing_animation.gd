extends Label

@export var type_speed : float = 0.03

var current_line : int = 0
var typing : bool = false

func play_typing(lines: Array[String]) -> void:
	typing = true
	for line in lines:
		text = line.replace("\\n", "\n")
		visible_characters = 0
		for i in range(text.length()):
			visible_characters = i + 1
			await get_tree().create_timer(type_speed).timeout
		await get_tree().create_timer(2.0).timeout
	visible_characters = -1
	typing = false
	text = ""
