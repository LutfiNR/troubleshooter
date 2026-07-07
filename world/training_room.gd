extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.load_chapter("chapter0")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
