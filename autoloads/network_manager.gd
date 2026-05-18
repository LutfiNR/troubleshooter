extends Node
class_name Networkmanager
signal device_updated(device_id: String)

enum PlayMode{
	MISSION,
	EXPLORATION
}

var play_mode: PlayMode
var computer_devices: Dictionary[String,ComputerDevice]
#var computer_devices: Dictionary[String,ServerDevice]
#var computer_devices: Dictionary[String,RouterDevice]
#var computer_devices: Dictionary[String,SwitchDevice]

func setup_device_data(_device)-> void:
	if _device is ComputerDevice:
		computer_devices[_device.device_id] = _device
		print("[NETWORK MANAGER] Total Computer Device: " + str(computer_devices.size()))
	print("[NETWORK MANAGER] "  + _device.device_id + " Device Added")

func remove_device_data(device_id: String)-> void:
	if computer_devices.get(device_id):
		computer_devices.erase(device_id)
		print("[NETWORK MANAGER] Total Device: " + str(computer_devices.size()))
	print("[NETWORK MANAGER] "  + device_id + " Device Removed")
	
func get_device(device_id: String):
	if computer_devices.get(device_id):
		return computer_devices.get(device_id)
	return null

func set_device_power(device_id: String)-> void:
	var dev = get_device(device_id)
	if dev == null:
		return
	if dev.power == NetworkDevice.PowerState.ON:
		dev.set_power(NetworkDevice.PowerState.OFF)
	else:
		dev.set_power(NetworkDevice.PowerState.ON)
	print("[NetworkManager] ", dev.id, "'s Power State change to ", dev.power)
	device_updated.emit(device_id)
