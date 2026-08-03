extends Line2D

@export var device_a: StaticBody2D
@export var device_b: StaticBody2D

var cable_data: CableData

func _ready() -> void:
	NetworkManager.cable_updated.connect(_on_cable_updated)
	NetworkManager.devices_initialized.connect(_on_devices_initialized)
	if not NetworkManager.runtime_cables.is_empty():
		_initialize_cable_data()

func _on_devices_initialized() -> void:
	_initialize_cable_data()

func _initialize_cable_data() -> void:
	var cables_data = NetworkManager.get_cables_for_device(device_a.device_data)
	for cable in cables_data:
		if cable.device_a == device_a.device_data and cable.device_b == device_b.device_data:
			cable_data = cable
	_update_visual()

func _on_cable_updated(_cable_id: String, _cable_data: CableData) -> void:
	cable_data = _cable_data
	_update_visual()

func _update_visual() -> void:
	if not device_a or not device_b:
		return
	global_position = Vector2.ZERO
	points = [device_a.global_position, device_b.global_position]
