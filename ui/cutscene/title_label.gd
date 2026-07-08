extends Label

@onready var label: Label = $"../Label"

func _ready() -> void:
	await label.typing_finished
	show()
	
