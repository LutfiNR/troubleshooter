extends Node2D

@onready var port: Port = $Port
@onready var cable: Cable = $Cable
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	cable.plug_state_changed.connect(port.set_plugged)
	camera.make_current()


func _on_texture_button_pressed() -> void:
	queue_free()
