extends Node

signal device_updated(device_id: String)

# Runtime device storage
var computer_devices: Dictionary[String, ComputerDevice] = { }
var server_devices: Dictionary[String, ServerDevice] = { }
var router_devices: Dictionary[String, RouterDevice] = { }
var switch_devices: Dictionary[String, SwitchDevice] = { }


func _ready():
	call_deferred("setup_devices")


func setup_devices() -> void:
	for device_id in computer_devices:
		computer_devices[device_id].setup_device()
	for device_id in server_devices:
		server_devices[device_id].setup_device()
	for device_id in router_devices:
		router_devices[device_id].setup_device()
	for device_id in switch_devices:
		switch_devices[device_id].setup_device()
	device_updated.emit("")


func add_device_data(device_data: NetworkDevice) -> void:
	if not device_data or device_data.device_id.is_empty():
		return

	var id = device_data.device_id
	if device_data is ComputerDevice:
		computer_devices[id] = device_data
	elif device_data is ServerDevice:
		server_devices[id] = device_data
	elif device_data is RouterDevice:
		router_devices[id] = device_data
	elif device_data is SwitchDevice:
		switch_devices[id] = device_data

	print("[NetworkDeviceManager] Device Added: ", id)


func remove_device_data(device_id: String) -> void:
	if computer_devices.erase(device_id):
		pass
	elif server_devices.erase(device_id):
		pass
	elif router_devices.erase(device_id):
		pass
	elif switch_devices.erase(device_id):
		pass

	print("[NetworkDeviceManager] Device Removed: ", device_id)


func get_device_data(device_id: String) -> NetworkDevice:
	if computer_devices.has(device_id):
		return computer_devices[device_id]
	if server_devices.has(device_id):
		return server_devices[device_id]
	if router_devices.has(device_id):
		return router_devices[device_id]
	if switch_devices.has(device_id):
		return switch_devices[device_id]
	return null


func get_all_devices() -> Array[NetworkDevice]:
	var all_devices: Array[NetworkDevice] = []
	all_devices.append_array(computer_devices.values())
	all_devices.append_array(server_devices.values())
	all_devices.append_array(router_devices.values())
	all_devices.append_array(switch_devices.values())
	return all_devices


func set_device_power(device_id: String) -> void:
	var device = get_device_data(device_id)
	if not device:
		return

	if device.power == NetworkDevice.PowerState.ON:
		device.set_power(NetworkDevice.PowerState.OFF)
	else:
		device.set_power(NetworkDevice.PowerState.ON)

	print("[NetworkDeviceManager] ", device.device_id, "'s Power State changed to ", device.power)
	device_updated.emit(device_id)


func set_interface_state(device_id: String, interface_id: String, is_up: bool) -> void:
	var device = get_device_data(device_id)
	if device and device.has_interface(interface_id):
		var iface = device.get_interface(interface_id)
		iface.state = NetworkInterface.InterfaceState.UP if is_up else NetworkInterface.InterfaceState.DOWN
		device_updated.emit(device_id)
		print("[NetworkDeviceManager] %s pada %s diubah menjadi %s" % [interface_id, device_id, "UP" if is_up else "DOWN"])


func update_device(device_id: String, device_data: NetworkDevice) -> void:
	if not device_data:
		return

	# Hapus data lama lalu timpa dengan yang baru
	remove_device_data(device_id)
	add_device_data(device_data)

	print("[NetworkDeviceManager] ", device_data.device_id, " Device Updated")
	device_updated.emit(device_id)
