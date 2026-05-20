extends Node
signal device_updated(device_id: String)

# Runtime device storage
var computer_devices: Dictionary[String,ComputerDevice]
#var server_devices: Dictionary[String,ServerDevice]
#var router_devices: Dictionary[String,RouterDevice]
#var switch_devices: Dictionary[String,SwitchDevice]

func add_device_data(device_data: NetworkDevice)-> void:
	if device_data is ComputerDevice:
		computer_devices[device_data.device_id] = device_data
		print("[NetworkDeviceManager] Total Computer Device: " + str(computer_devices.size()))
	# if device_data is RouterDevice:
	# 	router_devices[device_data.device_id] = device_data
	# 	print("[NetworkDeviceManager] Total Router Device: " + str(computer_devices.size()))
	# if device_data is SwitchDevice:
	# 	switch_devices[device_data.device_id] = device_data
	# 	print("[NetworkDeviceManager] Total Switch Device: " + str(computer_devices.size()))
	# if device_data is ServerDevice:
	# 	server_devices[device_data.device_id] = device_data
	# 	print("[NetworkDeviceManager] Total Server Device: " + str(computer_devices.size()))
	print("[NetworkDeviceManager] "  + device_data.device_id + " Device Added")

func remove_device_data(device_id: String)-> void:
	if computer_devices.get(device_id):
		computer_devices.erase(device_id)
		print("[NetworkDeviceManager] Total Device: " + str(computer_devices.size()))
	# if server_devices.get(device_id):
	# 	server_devices.erase(device_id)
	# 	print("[NetworkDeviceManager] Total Device: " + str(server_devices.size()))
	# if switch_devices.get(device_id):
	# 	switch_devices.erase(device_id)
	# 	print("[NetworkDeviceManager] Total Device: " + str(switch_devices.size()))
	# if router_devices.get(device_id):
	# 	router_devices.erase(device_id)
	# 	print("[NetworkDeviceManager] Total Device: " + str(router_devices.size()))
		print("[NetworkDeviceManager] "  + device_id + " Device Removed")
	
func get_device_data(device_id: String):
	if computer_devices.get(device_id):
		return computer_devices.get(device_id)
	# if server_devices.get(device_id):
	# 	return server_devices.get(device_id)
	# if switch_devices.get(device_id):
	# 	return switch_devices.get(device_id)
	# if router_devices.get(device_id):
	# 	return router_devices.get(device_id)
	return null

func set_device_power(device_id: String)-> void:
	var device = get_device_data(device_id)
	if not device:
		return
	if device.power == NetworkDevice.PowerState.ON:
		device.set_power(NetworkDevice.PowerState.OFF)
	else:
		device.set_power(NetworkDevice.PowerState.ON)
	computer_devices[device_id] = device
	print("[NetworkDeviceManager] ", device.device_id, "'s Power State change to ", device.power)
	device_updated.emit(device_id)

func update_device(device_id: String, device_data: NetworkDevice)-> void:
	if device_data is ComputerDevice:
		computer_devices[device_data.device_id] = device_data
	# if device_data is RouterDevice:
	# 	router_devices[device_data.device_id] = device_data
	# 	print("[NetworkDeviceManager] Total Router Device: " + str(computer_devices.size()))
	# if device_data is SwitchDevice:
	# 	switch_devices[device_data.device_id] = device_data
	# 	print("[NetworkDeviceManager] Total Switch Device: " + str(computer_devices.size()))
	# if device_data is ServerDevice:
	# 	server_devices[device_data.device_id] = device_data
	# 	print("[NetworkDeviceManager] Total Server Device: " + str(computer_devices.size()))
	print("[NetworkDeviceManager] "  + device_data.device_id + " Device Updated")
	device_updated.emit(device_id)
