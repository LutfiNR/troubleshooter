extends Node2D

@export var ui_container: Control
@onready var camera: Camera2D = $Camera2D

var device_id: String

func _ready() -> void:
	camera.make_current()
	if ui_container and ui_container.has_method("setup"):
		ui_container.setup(device_id)
		
	NetworkDeviceManager.device_updated.connect(_on_device_updated)
	_update_visual()

func _on_device_updated(updated_device_id: String) -> void:
	if updated_device_id == device_id:
		_update_visual()

func _update_visual() -> void:
	var device: RouterDevice = NetworkDeviceManager.get_device_data(device_id)
	if device == null: return
	
	# Gunakan .power, bukan .power_state
	if device.power == NetworkDevice.PowerState.OFF:
		ui_container.hide()
	else:
		ui_container.show()

func _on_exit_button_pressed() -> void:
	queue_free()
