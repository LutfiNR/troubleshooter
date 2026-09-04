extends Node2D

@export var ports: Array[Port]
@export var cables: Array[CableNode]
@onready var camera: Camera2D = $Camera2D

var device_id: String
var device: DeviceData


func _ready() -> void:
	camera.make_current()

	if device_id.is_empty():
		push_error("Overlay: device_id not set!")
		return

	device = NetworkManager.get_runtime_device_data_by_id(device_id)
	if device == null:
		push_error("Overlay: Device not found for id: " + device_id)
		return

	var interfaces = device.get_interfaces()
	var device_cables = NetworkManager.get_cables_for_device(device)
	for i in interfaces.size():
		var port = ports[i]
		var interface_data = interfaces[i]
		port.id = interface_data.id
		port.device_id = device_id
		var has_cable_connection = false
		for cable_data: CableData in device_cables:
			if (
				cable_data.interface_id_a == interface_data.id
				or cable_data.interface_id_b == interface_data.id
			):
				has_cable_connection = true
				break
		port.can_accept_cable = has_cable_connection
	NetworkManager.device_updated.connect(_on_device_updated)
	update_ui(device)


func _on_device_updated(updated_device_id: String, device_data: DeviceData) -> void:
	if updated_device_id == device_id:
		device = device_data
		update_ui(device)


func update_ui(target_device: DeviceData) -> void:
	if target_device == null:
		return
	var interfaces = target_device.get_interfaces()
	var device_cables = NetworkManager.get_cables_for_device(target_device)

	for i in interfaces.size():
		var port = ports[i]
		var interface_data = interfaces[i]
		port.update_visual(interface_data, target_device.power)

		if i < cables.size():
			var cable = cables[i]
			# Check if this interface has a cable connection in runtime
			var has_cable_connection = false
			for cable_data: CableData in device_cables:
				if (
					cable_data.interface_id_a == interface_data.id
					or cable_data.interface_id_b == interface_data.id
				):
					has_cable_connection = true
					break
			cable.visible = has_cable_connection
			cable.force_state_from_data(port, interface_data.is_up())


func _on_exit_button_pressed() -> void:
	queue_free()
