extends Node2D

@export var ports: Array[Port]
@export var cables: Array[CableNode]
@onready var camera: Camera2D = $Camera2D

var device_id: String
var device: NetworkDevice

func _ready() -> void:
	camera.make_current()
	
	if device_id.is_empty():
		push_error("Overlay: device_id not set!")
		return
		
	device = NetworkDeviceManager.get_device_data(device_id)
	if device == null:
		push_error("Overlay: Device not found for id: " + device_id)
		return
		
	# Sinkronisasi metadata Port
	# Kita ambil .values() karena interfaces di NetworkDevice berbentuk Dictionary
	var interfaces_array = device.get_interfaces().values()
	for i in range(min(ports.size(), interfaces_array.size())):
		var port = ports[i]
		var interface_data = interfaces_array[i]
		port.id = interface_data.id
		port.device_id = device_id
	
	# Dengarkan perubahan jika terjadi update dari sistem
	NetworkDeviceManager.device_updated.connect(_on_network_updated)
	update_ui(device)

func _on_network_updated(updated_device_id: String) -> void:
	if updated_device_id == device_id:
		# Tarik data device terbaru untuk berjaga-jaga
		device = NetworkDeviceManager.get_device_data(device_id)
		update_ui(device)

func update_ui(target_device: NetworkDevice) -> void:
	if target_device == null: return
		
	var interfaces_array = target_device.get_interfaces().values()
	for i in range(min(ports.size(), interfaces_array.size())):
		var port = ports[i]
		var interface_data = interfaces_array[i]
		
		# Menggunakan target_device.power (bukan power_state)
		port.update_visual(interface_data, target_device.power) 
		
		if i < cables.size():
			var cable = cables[i]
			cable.visible = true
			cable.force_state_from_data(port, interface_data.is_up())

func _on_exit_button_pressed() -> void:
	queue_free()
