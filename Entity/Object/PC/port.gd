extends Node2D
class_name Port

@onready var sprite: Sprite2D = $Port

var _is_plugged: bool = false

func set_plugged(value: bool) -> void:
	if _is_plugged == value:
		return
		
	_is_plugged = value
	_update_visual()


func _update_visual() -> void:
	sprite.frame = 1 if _is_plugged else 0
